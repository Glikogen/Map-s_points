import QtQuick 2.12
import QtQml 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 1.4
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Styles 1.4
import Qt.labs.qmlmodels 1.0
import QtQuick.Dialogs 1.2
import ModelView 1.0

Item {
    id: rootItem

    function setAngles(angle1, angle2) {
        console.log("angle1 = " + angle1 + "; angle2 = " + angle2);
        modelView.alfa1 = angle1;
        modelView.alfa2 = angle2;
    }

    ModelView {
        id: modelView

        //свойства для карты
        property string mapName
        property real topLeftLatitude
        property real topLeftLongitude
        property real bottomRightLatitude
        property real bottomRightLongitude
        property string pathToImage

        //углы
        property real alfa1
        property real alfa2

        onSendMapImageData: (map_name, top_left_latitude, top_left_longitude, bottom_right_latitude, bottom_right_longitude, path_to_image) => {
                                mapName = map_name;
                                topLeftLatitude = top_left_latitude;
                                topLeftLongitude = top_left_longitude;
                                bottomRightLatitude = bottom_right_latitude;
                                bottomRightLongitude = bottom_right_longitude;
                                pathToImage = path_to_image;
                            }
    }

    ColumnLayout{
        anchors.fill: parent
        spacing: 5
        Item {
            id:rootMap
            Layout.fillHeight: true
            Layout.fillWidth: true

            Flickable {
                id: mapFrame
                anchors.fill: parent
                focus: true
                clip: true

                anchors.centerIn: parent
                boundsBehavior: Flickable.StopAtBounds

                contentWidth: Math.max(mapImage.width * mapImage.scale, rootMap.width)
                contentHeight: Math.max(mapImage.height * mapImage.scale, rootMap.height)

                //deltaX - дельта изменения x про прокрутке
                //deltaY- дельта изменения y про прокрутке
                property real deltaX: mapImage.width/10 //делим на 10 - потому что stepSize слайдера = 0.1, то есть увеличение карты при прокрутке = 10%
                property real deltaY: mapImage.height/10

                //        //левый верхний угол
                property real zeroPointLongitude: modelView.topLeftLongitude
                property real zeroPointLatitude: modelView.topLeftLatitude
                //правый нижний угол
                property real endPointLongitude: modelView.bottomRightLongitude
                property real endPointLatitude: modelView.bottomRightLatitude

                property real deltaFullLongitude: Math.abs(endPointLongitude - zeroPointLongitude)
                property real deltaFullLatitude: Math.abs(endPointLatitude - zeroPointLatitude)

                property real mouseXCoordinate: zeroPointLongitude.toFixed(5)
                property real mouseYCoordinate: zeroPointLatitude.toFixed(5)

                Image {
                    id: mapImage

                    property alias zoom: slider.value
                    //1000 - это колво пискелей
                    property int markerScale: (mapImage.height/1000).toFixed() < 1? 1 : (mapImage.height/1000).toFixed();
                    property int markerScaleKoef: parseInt(((mapFrame.contentHeight + mapFrame.contentWidth)/1000).toFixed());

                    scale: Math.min(rootMap.width / width, rootMap.height / height, 1) + slider.value

                    asynchronous: true
                    cache: false
                    smooth: true
                    antialiasing: true
                    mipmap: true
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    transformOrigin: Item.Center
                    source: Qt.resolvedUrl(modelView.pathToImage)

                    Repeater {
                        id: repeater_canvas
                        property bool is_ma1_active: false
                        property bool is_ma2_active: false
                        model: point_model
                        delegate: Canvas {
                            id: canvas
                            anchors.fill: parent

                            // Code to draw a simple arrow on TypeScript canvas got from https://stackoverflow.com/a/64756256/867349
                            function arrow(context, fromx, fromy, tox, toy) {

                                const dx = tox - fromx;
                                const dy = toy - fromy;
                                const headlen = Math.sqrt(dx * dx + dy * dy) * 0.25; // length of head in pixels
                                const angle = Math.atan2(dy, dx);
                                context.beginPath();
                                context.moveTo(fromx, fromy);
                                context.lineTo(tox, toy);
                                context.stroke();
                                context.beginPath();
                                context.moveTo(tox - headlen * Math.cos(angle - Math.PI / 6), toy - headlen * Math.sin(angle - Math.PI / 6));
                                context.lineTo(tox, toy);
                                context.lineTo(tox - headlen * Math.cos(angle + Math.PI / 6), toy - headlen * Math.sin(angle + Math.PI / 6));
                                //в зависимости от индекса(номера точки) выбираем угол
                                var beta = model.index === 0 ? modelView.alfa1 * Math.PI/180 : modelView.alfa2 * Math.PI/180;
                                var x2 = (tox - fromx)*Math.cos(beta)-(toy-fromy)*Math.sin(beta)+fromx;
                                var y2 = (tox - fromx)*Math.sin(beta)+(toy-fromy)*Math.cos(beta)+fromy;
                                context.stroke();

                                var k = 3;
                                var alfa = Math.atan2((y2 - fromy),(x2 - fromx));
                                var tempAlfa = alfa *180.0/Math.PI;
                                var mainAlfa = tempAlfa > 0 ? tempAlfa : 360 + tempAlfa;
                                const dx_temp = Math.abs(x2 - fromx);
                                const dy_temp = Math.abs(y2 - fromy);
                                var L = Math.sqrt(dx_temp * dx_temp + dy_temp * dy_temp);
                                var newx = k * L * Math.cos(alfa);
                                var newy = k * L * Math.sin(alfa);
                                x2 = fromx + newx;
                                y2 = fromy + newy;

                                const dx1 = x2 - fromx;
                                const dy1 = y2 - fromy;
                                const headlen1 = Math.sqrt(dx1 * dx1 + dy1 * dy1) * 0.25; // length of head in pixels
                                const angle1 = Math.atan2(dy1, dx1);
                                context.beginPath();
                                context.moveTo(fromx, fromy);
                                context.lineTo(x2, y2);
                                context.stroke();
                            }

                            function clearCanvas(){
                                var ctx = getContext("2d");
                                ctx.reset();
                            }

                            onPaint: {
                                // Get the canvas context
                                if (point_model.count === 0) return;
                                if (v1_button.vector_1_is_active === false && v2_button.vector_2_is_active === false) return;
                                var ctx = getContext("2d");
                                ctx.reset();
                                // Draw an arrow on given context starting at position (0, 0) -- top left corner up to position (mouseX, mouseY)
                                //   determined by mouse coordinates position
                                var x_zero = model.xpos;
                                var y_zero = model.ypos;
                                arrow(ctx, x_zero, y_zero, ma_canvas.mouseX, ma_canvas.mouseY);
                            }

                            MouseArea {
                                id: ma_canvas
                                anchors.fill: parent
                                enabled: model.index === 0 ? repeater_canvas.is_ma1_active : repeater_canvas.is_ma2_active
                                hoverEnabled: enabled ? true : false
                                // Do a paint requests on each mouse position change (X and Y separately)
                                onMouseXChanged: canvas.requestPaint()
                                onMouseYChanged: canvas.requestPaint()
                            }
                        }
                    }

                    MouseArea {
                        id: ma_points
                        anchors.fill: parent
                        onClicked: {
                            console.log("in ma_points");
                            var newPoint = {};
                            newPoint.xpos = mouseX;
                            newPoint.ypos = mouseY;
                            point_model.append(newPoint);
                        }
                    }

                    Repeater {
                        model: point_model
                        delegate: Rectangle {
                            id: rect_point
                            property string alfa_label: "P" + (index+1)

                            Text {
                                text: rect_point.alfa_label
                                color: "red"
                                font.pixelSize: 20
                                anchors.left: parent.right
                                anchors.bottom: parent.top
                                anchors.topMargin: -13
                                anchors.rightMargin: -13
                            }

                            width: 13
                            height: 13
                            scale: mapImage.markerScale / mapImage.markerScaleKoef
                            radius: width/2
                            color: "red"
                            x: xpos - radius
                            y: ypos - radius
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    point_model.remove(index);
                                }
                            }
                        }
                    }

                    ListModel {
                        id: point_model
                    }
                }

                interactive: v1_button.vector_1_is_active || v2_button.vector_2_is_active ? false : true;
//                onFlickStarted: {
//                    if (v1_button.vector_1_is_active || v2_button.vector_2_is_active) mapFrame.cancelFlick();
//                }

                MouseArea {
                    id: ma_for_flickable
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton

                    onPositionChanged: {
                        var propX = mouseX/mapFrame.contentWidth;
                        var propY = mouseY/mapFrame.contentHeight;

                        mapFrame.mouseXCoordinate = (mapFrame.zeroPointLongitude + mapFrame.deltaFullLongitude*propX).toFixed(5);
                        mapFrame.mouseYCoordinate = (mapFrame.zeroPointLatitude - mapFrame.deltaFullLatitude*propY).toFixed(5);
                    }
                    hoverEnabled: true

                    onWheel: {
                        if(v1_button.vector_1_is_active || v2_button.vector_2_is_active) return;

                        if (wheel.angleDelta.y > 0)
                            slider.value = Number((slider.value + slider.stepSize).toFixed(1));
                        else
                            slider.value = Number((slider.value - slider.stepSize).toFixed(1));
                        wheel.accepted = true;
                    }
                }
            }

            Text {
                id: textMouseX
                text: "X: " + mapFrame.mouseXCoordinate
                anchors.bottom: textMouseY.top
                anchors.left: parent.left
                anchors.margins: 5
                font.pointSize: 11
            }

            Text {
                id: textMouseY
                text: "Y: " + mapFrame.mouseYCoordinate
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 5
                font.pointSize: 11
            }

            Text {
                id: nameOfMap
                text: modelView.mapName
                font.pointSize: 12
                opacity: 0.5
                font.bold: true
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: 10
            }

            Button {
                id: v1_button
                height: 30
                property bool vector_1_is_active: false
                text: "Vector1"
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 5
                highlighted: vector_1_is_active
                onClicked: {
                    if (point_model.count < 1 || v2_button.vector_2_is_active) return;
                    vector_1_is_active = !vector_1_is_active;
                    if (vector_1_is_active) {
                        ma_points.enabled = false;
                        repeater_canvas.is_ma1_active = true;
                    }
                    else {
                        ma_points.enabled = true;
                        repeater_canvas.is_ma1_active = false;
                    }
                }
            }

            Button {
                id: v2_button
                height: 30
                text: "Vector2"
                property bool vector_2_is_active: false
                anchors.left: parent.left
                anchors.top: v1_button.bottom
                anchors.margins: 5
                highlighted: vector_2_is_active
                onClicked: {
                    if (point_model.count < 2 || v1_button.vector_1_is_active) return;
                    vector_2_is_active = !vector_2_is_active;

                    if (vector_2_is_active) {
                        ma_points.enabled = false;
                        repeater_canvas.is_ma2_active = true;
                    }
                    else {
                        ma_points.enabled = true;
                        repeater_canvas.is_ma2_active = false;
                    }
                }
            }

            Slider {
                id: slider
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 10
                orientation: Qt.Vertical
                from: 0.0
                value: 0.0
                stepSize: 0.1
                to: 5

                property real prevValue: value
                onValueChanged: {
                    var xcenterRation = (mapFrame.contentX + mapFrame.width/2)/mapFrame.contentWidth;
                    var ycenterRation = (mapFrame.contentY + mapFrame.height/2)/mapFrame.contentHeight;

                    if (value > prevValue)
                    {
                        mapFrame.contentX += xcenterRation * mapFrame.deltaX;
                        mapFrame.contentY += ycenterRation * mapFrame.deltaY;
                    }
                    else
                        if (value > 0)
                        {
                            mapFrame.contentX -= xcenterRation * mapFrame.deltaX;
                            mapFrame.contentY -= ycenterRation * mapFrame.deltaY;
                        }
                        else {
                            mapFrame.contentX = 0;
                            mapFrame.contentY = 0;
                        }
                }
            }
        }

        RowLayout {
            Layout.margins: 5
            spacing: 5
            Button {
                text: "Добавить карту..."
                onClicked: { dialogAddMap.open(); }

                Dialog { id: dialogAddMap; title: "Добавление новой карты"; contentItem: MapAddingDialog { id: dialogMapAddingRoot } }
            }

            ComboBox {
                id: comboBoxMaps
                model: modelView.mapNames

                onCurrentIndexChanged: {
                    point_model.clear();
                    modelView.currentMapChanged(currentIndex);
                }
            }

            Button {
                text: "Удалить карту"
                onClicked: { modelView.deleteCurrentMap(comboBoxMaps.currentIndex) }
            }
        }
    }
}

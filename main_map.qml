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
import Qt.labs.settings 1.1 //с версии QT 6.5 больше не поддерживаеьмся


Item {
    id: rootItem

    function setAngles(angles, bias){
        for(var i = 0; i < angles.length; i++){
            var is_angle_valid = true;
            if (bias[i] === 999 || angles[i] === 999) is_angle_valid = false;
            if (modelView.angles.count === i) {
                modelView.angles.append({ "offset": bias[i], "angle": angles[i], "flag": is_angle_valid });
            }
            else  {
                modelView.angles.get(i).offset = bias[i];
                modelView.angles.get(i).angle = angles[i];
                modelView.angles.get(i).flag = is_angle_valid;
            }

            modelView.angle = angles[i];
        }
    }

    property string datastore: ""
    property real map_index: 0

    Component.onCompleted: {
        comboBoxMaps.currentIndex = map_index;
        if (datastore){
            point_model.clear();
            var datamodel = JSON.parse(datastore);
            for(var i = 0; i < datamodel.length; i++) point_model.append(datamodel[i]);
        }
    }

    Component.onDestruction: {
        map_index = comboBoxMaps.currentIndex;
        var datamodel = [];
        for(var i = 0; i < point_model.count; i++) datamodel.push(point_model.get(i));
        datastore = JSON.stringify(datamodel);
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
        property real angle
        property ListModel angles: ListModel { }
//        property ListModel offsets: ListModel { }

        onSendMapImageData: (map_name, top_left_latitude, top_left_longitude, bottom_right_latitude, bottom_right_longitude, path_to_image) => {
                                mapName = map_name;
                                topLeftLatitude = top_left_latitude;
                                topLeftLongitude = top_left_longitude;
                                bottomRightLatitude = bottom_right_latitude;
                                bottomRightLongitude = bottom_right_longitude;
                                pathToImage = path_to_image;
                            }
    }

    ColorDialog {
        id: colorDialog
        title: "Выберите цвет"
        onAccepted: {
            console.log("Выбран: " + colorDialog.color)
        }
        onRejected: {
            console.log("Отменено")
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


                //КОСТЫЛЬ ДЛЯ 2х МОДУЛЕЙ
                //координаты пересечения направлений от первого и второго модуля
                property real crossingX: -1
                property real crossingY: -1

                //дистанция от первого и второго модулей до точки пересечения
                property real distance_fromP1: -1
                property real distance_fromP2: -1

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

                            property var angleVar: modelView.angle
                            onAngleVarChanged: {
                                canvas.requestPaint();
                            }

                            // Code to draw a simple arrow on TypeScript canvas got from https://stackoverflow.com/a/64756256/867349
                            function arrow(context, fromx, fromy, tox, toy) {

                                var k = 100;

                                //построение основной стрелки
                                toy = fromy*0.6;
                                const dx = tox - fromx;

                                //построение линии с учетом смещения delta
                                //999 в смещении - означает что нам не нужно ничего от этого модуля
                                if (modelView.angles.get(model.index).offset === 999) {
                                    mapFrame.crossingX = -1;
                                    mapFrame.crossingY = -1;
                                    mapFrame.distance_fromP1 = -1;
                                    mapFrame.distance_fromP2 = -1;
                                    return;
                                }

                                context.strokeStyle = colorDialog.color;
                                var delta = modelView.angles.get(model.index).offset * Math.PI/180;
                                var x1 = (tox - fromx)*Math.cos(delta)-(toy-fromy)*Math.sin(delta)+fromx;
                                var y1 = (tox - fromx)*Math.sin(delta)+(toy-fromy)*Math.cos(delta)+fromy;
                                var dx1 = x1 - fromx;
                                var dy1 = y1 - fromy;
                                var headlen1 = Math.sqrt(dx1 * dx1 + dy1 * dy1) * 0.1; // length of head in pixels
                                var angle1 = Math.atan2(dy1, dx1);
                                context.lineWidth = 2;
                                context.beginPath();
                                context.moveTo(fromx, fromy);
                                context.lineTo(x1, y1);
                                context.stroke();
                                context.beginPath();
                                context.moveTo(x1 - headlen1 * Math.cos(angle1 - Math.PI / 8), y1 - headlen1 * Math.sin(angle1 - Math.PI / 8));
                                context.lineTo(x1, y1);
                                context.lineTo(x1 - headlen1 * Math.cos(angle1 + Math.PI / 8), y1 - headlen1 * Math.sin(angle1 + Math.PI / 8));
                                context.stroke();


                                //построение линии с учетом угла альфа
                                //999 в углу - означает что нам не нужно направление на источник от этого модуля
                                if (modelView.angles.get(model.index).angle === 999) {
                                    mapFrame.crossingX = -1;
                                    mapFrame.crossingY = -1;
                                    mapFrame.distance_fromP1 = -1;
                                    mapFrame.distance_fromP2 = -1;
                                    return;
                                }

                                var beta = modelView.angles.get(model.index).angle * Math.PI/180;
                                var x2 = (x1 - fromx)*Math.cos(beta)-(y1-fromy)*Math.sin(beta)+fromx;
                                var y2 = (x1 - fromx)*Math.sin(beta)+(y1-fromy)*Math.cos(beta)+fromy;

                                var alfa = Math.atan2((y2 - fromy),(x2 - fromx));
                                var tempAlfa = alfa *180.0/Math.PI;
                                var mainAlfa = tempAlfa > 0 ? tempAlfa : 360 + tempAlfa;
                                var dx_temp = Math.abs(x2 - fromx);
                                var dy_temp = Math.abs(y2 - fromy);
                                var L = Math.sqrt(dx_temp * dx_temp + dy_temp * dy_temp);
                                var newx = k * L * Math.cos(alfa);
                                var newy = k * L * Math.sin(alfa);

                                x2 = fromx + newx;
                                y2 = fromy + newy;

                                dx1 = x2 - fromx;
                                dy1 = y2 - fromy;
                                headlen1 = Math.sqrt(dx1 * dx1 + dy1 * dy1) * 0.25; // length of head in pixels
                                angle1 = Math.atan2(dy1, dx1);
                                context.beginPath();
                                context.moveTo(fromx, fromy);
                                context.lineTo(x2, y2);
                                context.stroke();

                                if (point_model.count < 2) {
                                    mapFrame.crossingX = -1;
                                    mapFrame.crossingY = -1;
                                    mapFrame.distance_fromP1 = -1;
                                    mapFrame.distance_fromP2 = -1;
                                    return;
                                }

                                //КОСТЫЛЬ ДЛЯ 2х МОДУЛЕЙ
                                //пока что работает только с первым и вторым модулями!!!
                                var X1 = point_model.get(0).xpos;
                                var Y1 = point_model.get(0).ypos;

                                var X2 = point_model.get(1).xpos;
                                var Y2 = point_model.get(1).ypos;

                                var m = 1/Math.tan(modelView.angles.get(0).angle/180*Math.PI);
                                var n = 1/Math.tan(modelView.angles.get(1).angle/180*Math.PI);
                                var x = (m * X1 + Y1 - Y2 - n * X2)/(m-n);
                                var y = -m*(x - X1) + Y1;

                                /////////поиск новых точек

                                var new_alfa1 = modelView.angles.get(0).angle;
                                var new_alfa2 = modelView.angles.get(1).angle;
//                                var alfa1_inRad = new_alfa1/180*Math.PI;
//                                var alfa2_inRad = new_alfa2/180*Math.PI;

//                                var DX1 = Math.abs(X1 - x);
//                                var DY1 = Math.abs(Y1 - y);
//                                var LEN1 = Math.sqrt(DX1 * DX1 + DY1 * DY1);
//                                var DX2 = Math.abs(X2 - x);
//                                var DY2 = Math.abs(Y2 - y);
//                                var LEN2 = Math.sqrt(DX2 * DX2 + DY2 * DY2);

//                                var X1_end = LEN1 * Math.sin(alfa1_inRad) + X1;
//                                var Y1_end = Math.abs(LEN1 * Math.cos(alfa1_inRad) - Y1);

//                                var X2_end = LEN2 * Math.sin(alfa2_inRad) + X2;
//                                var Y2_end = Math.abs(LEN2 * Math.cos(alfa2_inRad) - Y2);

//                                ////////////конец поиска
//                                /////проверка на пересечение лучей
//                                var BAx = X1_end - X1;
//                                var BAy = Y1_end - Y1;

//                                var DCx = X2_end - X2;
//                                var DCy = Y2_end - Y2;

//                                var K2 = ((X1_end-X1)*(Y1-Y2)-Y1_end*X2+Y1_end*X1+Y1*X2-Y1*X1)/((X2_end-X2)*(Y1_end-Y1)-(Y2_end-Y2)*(X1_end-X1));
//                                var K1 = (X2-X1+(X2_end-X2)*K2)/(X1_end-X1);

//                                var K2 = (BAy*X1+X2*BAx-Y1*BAx-X2*BAy)/(BAy*DCx-DCy*BAx);
//                                var K2 = -1*(BAy*X1+X2*BAx-Y1*BAx-X2*BAy)/(-BAy*DCx+DCy*BAx);
//                                var K1 = (DCx*K2+X2-X1)/BAx;


                                var first_ray_toTop = new_alfa1 < 90 || new_alfa1 > 269 ? true : false;
                                var second_ray_toTop = new_alfa2 < 90 || new_alfa2 > 269 ? true : false;
                                var is_crossing_point_real = true;

                                //если первый луч смотрит вверх и точка пересечения лежит ниже начала луча
                                if (first_ray_toTop && y > Y1) is_crossing_point_real = false;
                                //если второй луч смотрит вверх и точка пересечения лежит ниже начала луча
                                if (second_ray_toTop && y > Y2) is_crossing_point_real = false;
                                //если первый луч смотрит вниз и точка пересечения лежит выше начала луча
                                if (!first_ray_toTop && y < Y1) is_crossing_point_real = false;
                                //если второй луч смотрит вверх и точка пересечения лежит ниже начала луча
                                if (!second_ray_toTop && y < Y2) is_crossing_point_real = false;

//                                console.log("is_crossing_point_real = " + is_crossing_point_real);
                                /////конец проверки


                                var propX = Math.abs(x)/mapImage.width;
                                var propY = Math.abs(y)/mapImage.height;

                                //если точка пересечения лежит за пределами карты
                                if(x < 0 || y < 0 || x > mapImage.width || y > mapImage.height) {
                                    mapFrame.crossingX = -1;
                                    mapFrame.crossingY = -1;
                                } else {

                                    mapFrame.crossingX = (mapFrame.zeroPointLongitude + mapFrame.deltaFullLongitude*propX).toFixed(5);
                                    mapFrame.crossingY = (mapFrame.zeroPointLatitude - mapFrame.deltaFullLatitude*propY).toFixed(5);

                                    //получаем координаты 2-х модулей
                                    var p1X = (mapFrame.zeroPointLongitude + mapFrame.deltaFullLongitude*X1/mapImage.width).toFixed(5);
                                    var p1Y = (mapFrame.zeroPointLatitude - mapFrame.deltaFullLatitude*Y1/mapImage.height).toFixed(5);
                                    var p2X = (mapFrame.zeroPointLongitude + mapFrame.deltaFullLongitude*X2/mapImage.width).toFixed(5);
                                    var p2Y = (mapFrame.zeroPointLatitude - mapFrame.deltaFullLatitude*Y2/mapImage.height).toFixed(5);

                                    mapFrame.distance_fromP1 = (getDistance(p1Y, p1X, mapFrame.crossingY, mapFrame.crossingX)).toFixed(1);
                                    mapFrame.distance_fromP2 = (getDistance(p2Y, p2X, mapFrame.crossingY, mapFrame.crossingX)).toFixed(1);
                                }

                                //КОСТЫЛЬ ДЛЯ 2х МОДУЛЕЙ
                                if (modelView.angles.get(0).flag === false || modelView.angles.get(1).flag === false || !is_crossing_point_real) {
                                    mapFrame.crossingX = -1;
                                    mapFrame.crossingY = -1;
                                    mapFrame.distance_fromP1 = -1;
                                    mapFrame.distance_fromP2 = -1;
                                    return;
                                }

                                //выделяем точку пересечения пожирнее
                                context.beginPath();
                                context.arc(x, y, 3, 0, 2 * Math.PI);
                                context.stroke();
                            }

                            //функция вычисления дистанции по двум координатам
                            function getDistance(lat1, lon1, lat2, lon2){
                                var distance = 0.0;
                                if((lon1 === lon2) && (lat1 === lat2)) return distance;

                                var rad = 6372795;
                                //в радианы
                                var latid1 = lat1*Math.PI/180.0;
                                var latid2 = lat2*Math.PI/180.0;
                                var long1 = lon1*Math.PI/180.0;
                                var long2 = lon2*Math.PI/180.0;

                                //косинусы и синусы широт и разницы долгот
                                var coslat1 = Math.cos(latid1);
                                var coslat2 = Math.cos(latid2);
                                var sinlat1 = Math.sin(latid1);
                                var sinlat2 = Math.sin(latid2);
                                var delta = long2 - long1;
                                var cosdelta = Math.cos(delta);
                                var sindelta = Math.sin(delta);

                                //вычисления длины большого круга
                                var y = Math.sqrt(Math.pow(coslat2*sindelta, 2) + Math.pow(coslat1*sinlat2 - sinlat1*coslat2*cosdelta, 2));
                                var x = sinlat1*sinlat2 + coslat1*coslat2*cosdelta;
                                var ad = Math.atan2(y,x);
                                distance = ad*rad;

                                return distance;
                            }

                            function clearCanvas(){
                                var ctx = getContext("2d");
                                ctx.reset();
                            }

                            onPaint: {
                                // Get the canvas context
                                if (point_model.count === 0) return;
                                var ctx = getContext("2d");
                                ctx.reset();
                                // Draw an arrow on given context starting at position (0, 0) -- top left corner up to position (mouseX, mouseY)
                                //   determined by mouse coordinates position
                                var x_zero = model.xpos;
                                var y_zero = model.ypos;

                                arrow(ctx, x_zero, y_zero, x_zero, y_zero);
                            }

                            MouseArea {
                                id: ma_canvas
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    canvas.requestPaint();
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: ma_for_flickable
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton

                        onPositionChanged: {
                            var propX = mouseX/mapImage.width;
                            var propY = mouseY/mapImage.height;

                            mapFrame.mouseXCoordinate = (mapFrame.zeroPointLongitude + mapFrame.deltaFullLongitude*propX).toFixed(5);
                            mapFrame.mouseYCoordinate = (mapFrame.zeroPointLatitude - mapFrame.deltaFullLatitude*propY).toFixed(5);
                        }
                        hoverEnabled: true

                        onWheel: {

                            if (wheel.angleDelta.y > 0)
                                slider.value = Number((slider.value + slider.stepSize).toFixed(1));
                            else
                                slider.value = Number((slider.value - slider.stepSize).toFixed(1));
                            wheel.accepted = true;
                        }
                    }

                    MouseArea {
                        id: ma_points
                        anchors.fill: parent
                        onClicked: {
                            if (point_model.count >= modelView.angles.count) return;
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

                    Settings {
                        id: settings
                        property alias datastore: rootItem.datastore
                        property alias map_index: rootItem.map_index
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
                id: btn_color_choosing
                anchors.margins: 10
                anchors.left: parent.left
                anchors.top: parent.top
                height: 30
                width: 30
                background: Rectangle {
                    radius: 15
                    opacity: 0.5
                    color: btn_color_choosing.down ? "grey" : colorDialog.color
                }

                onClicked: {
                    colorDialog.open();
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
            Layout.maximumHeight: 60

            ColumnLayout {
                Layout.fillHeight: true
                Layout.maximumWidth: 120
                Button {
                    id: btn_add_map
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    text: "Добавить карту..."
                    onClicked: { dialogAddMap.open(); }

                    Dialog { id: dialogAddMap; title: "Добавление новой карты"; contentItem: MapAddingDialog { id: dialogMapAddingRoot } }
                }

                Button {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    text: "Удалить карту"
                    onClicked: { modelView.deleteCurrentMap(comboBoxMaps.currentIndex) }
                }
            }

            ComboBox {
                id: comboBoxMaps
                Layout.fillHeight: true
                model: modelView.mapNames

                onCurrentIndexChanged: {
                    point_model.clear();
                    modelView.currentMapChanged(currentIndex);
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.maximumWidth: 140
                Layout.minimumWidth: 90

                Rectangle {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    border.color: "gray"
                    border.width: 1
                    Text {
                        anchors.fill: parent
                        property string text_value: mapFrame.crossingX === -1 ? "P1-P2 X: за пределами" : "P1-P2 X: " + mapFrame.crossingX
                        text: text_value
                        padding: 2
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    border.color: "gray"
                    border.width: 1
                    Text {
                        anchors.fill: parent
                        property string text_value: mapFrame.crossingY === -1 ? "P1-P2 Y: за пределами" : "P1-P2 Y: " + mapFrame.crossingY
                        text: text_value
                        padding: 2
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Rectangle{
                id: rect_for_list
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.minimumWidth: 100
                ListView {
                    id: dist_list
                    anchors.fill: parent
                    model: point_model
                    delegate: Rectangle {
                        width: rect_for_list.width
                        border.color: "gray"
                        border.width: 1
                        height: comboBoxMaps.height/point_model.count
                        Text {
                            id: text_dist
                            anchors.fill: parent
                            property real dist: model.index === 0 ? mapFrame.distance_fromP1 : mapFrame.distance_fromP2
                            property string text_value: "L от " + (model.index+1) + " модуля: " + dist + " м"
                            text: mapFrame.distance_fromP1 === -1 || mapFrame.distance_fromP2 === -1 ? "не определена" : text_value
                            padding: 2
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                        }
                    }
                }
            }
        }
    }
}

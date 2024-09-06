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

    //функция (слот) для приема углов и смещений из MainWindow
    function setAngles(angles, bias){
        for(var i = 0; i < angles.length; i++){
            var is_angle_valid = true;
            if (bias[i] === 999 || angles[i] === 999) is_angle_valid = false;
            if (modelView.angles.count === i) { //если в Списке углов 0 обьектов, то добавить первый обьект с соответствующими свойствами
                modelView.angles.append({ "offset": bias[i], "angle": angles[i], "flag": is_angle_valid });
            }
            else  {
                modelView.angles.get(i).offset = bias[i];
                modelView.angles.get(i).angle = angles[i];
                modelView.angles.get(i).flag = is_angle_valid;

                modelView.angle = angles[i];
            }
        }
    }

    //эти свойства сохраняют свои значения при закрытии программы и заполняются при открытии
    property string datastore: ""
    property real map_index: 0
    property color color: "grey"

    Component.onCompleted: {
        //при запуске программы указываем, какую карту открыть (map_index), какие точки стояли (datastore), и какой цвет был выбран (color)
        comboBoxMaps.currentIndex = map_index;
        colorDialog.color = color;
        if (datastore){
            point_model.clear();
            var datamodel = JSON.parse(datastore);
            for(var i = 0; i < datamodel.length; i++) point_model.append(datamodel[i]);
        }
    }

    Component.onDestruction: {
        //при закрытии программы эти свойства сохраняют свои значения
        map_index = comboBoxMaps.currentIndex;
        color = colorDialog.color;
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
        property ListModel angles: ListModel { }//список углов
        property ListModel points: ListModel { }//трекинг точек пересечения

        //слот для получения данных о карте из ViewModel
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
            //корневой елемент работы карты
            id:rootMap
            Layout.fillHeight: true
            Layout.fillWidth: true

            Flickable {
                //элемент для перемещения по карте (картинке карты)
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

                //левый верхний угол
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
                    //картинка с картой
                    id: mapImage

                    property alias zoom: slider.value
                    //1000 - это кол-во пискелей
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


                    ListModel {
                        id: point_model
                    }

                    Repeater {
                        //повторитель красных точек на карте (модулей)
                        id: repeater_canvas

                        model: point_model
                        delegate: Canvas {
                            id: canvas
                            anchors.fill: parent

                            //полукостыль: когда приходит новый угол, автоматически меняется свойство angleVar, а когда angleVar меняется, то
                            //мы вызываем canvas.requestPaint() - перерисовку объектов на карте
                            property real angleVar: modelView.angle
                            onAngleVarChanged: {
                                canvas.requestPaint();
                            }

                            //функция, чтобы нарисовать все обьекты на карте
                            function draw_All_Elements(context, fromx, fromy, tox, toy) {

                                //коэф увеличения приямой линии (в k раз больше основной стрелки)
                                var k = 100;

                                //построение основной стрелки
                                toy = fromy*0.6;
                                const dx = tox - fromx;

                                //построение линии с учетом смещения delta
                                //999 в смещении - означает что нам не нужно ничего от этого модуля
                                if (modelView.angles.get(model.index).offset === 999) { //"обнуляем" все, если смещение невалидное
                                    mapFrame.crossingX = -1;
                                    mapFrame.crossingY = -1;
                                    mapFrame.distance_fromP1 = -1;
                                    mapFrame.distance_fromP2 = -1;
                                    return;
                                }

                                context.strokeStyle = colorDialog.color;
                                var delta = modelView.angles.get(model.index).offset * Math.PI/180;//угол смещения
                                var x1 = (tox - fromx)*Math.cos(delta)-(toy-fromy)*Math.sin(delta)+fromx;
                                var y1 = (tox - fromx)*Math.sin(delta)+(toy-fromy)*Math.cos(delta)+fromy;
                                var dx1 = x1 - fromx;
                                var dy1 = y1 - fromy;
                                var headlen1 = Math.sqrt(dx1 * dx1 + dy1 * dy1) * 0.1; // длина маленьких линий (боковые стрелочки) у стрелки в пикселях
                                var angle1 = Math.atan2(dy1, dx1);
                                context.lineWidth = 2;
                                context.beginPath();
                                context.moveTo(fromx, fromy);
                                context.lineTo(x1, y1);//рисуем линию
                                context.stroke();
                                context.beginPath();
                                context.moveTo(x1 - headlen1 * Math.cos(angle1 - Math.PI / 8), y1 - headlen1 * Math.sin(angle1 - Math.PI / 8));//рисуем боковые стрелочки
                                context.lineTo(x1, y1);
                                context.lineTo(x1 - headlen1 * Math.cos(angle1 + Math.PI / 8), y1 - headlen1 * Math.sin(angle1 + Math.PI / 8));//рисуем боковые стрелочки
                                context.stroke();


                                //построение линии с учетом угла альфа
                                //999 в углу - означает что нам не нужно направление на источник от этого модуля
                                if (modelView.angles.get(model.index).angle === 999) { //"обнуляем" все, если угол невалидный
                                    mapFrame.crossingX = -1;
                                    mapFrame.crossingY = -1;
                                    mapFrame.distance_fromP1 = -1;
                                    mapFrame.distance_fromP2 = -1;
                                    return;
                                }


                                var beta = modelView.angles.get(model.index).angle * Math.PI/180;//получаем угол
                                var x2 = (x1 - fromx)*Math.cos(beta)-(y1-fromy)*Math.sin(beta)+fromx;
                                var y2 = (x1 - fromx)*Math.sin(beta)+(y1-fromy)*Math.cos(beta)+fromy;
                                //расчет как строить угол отклонения
                                var alfa = Math.atan2((y2 - fromy),(x2 - fromx));
                                var dx_temp = Math.abs(x2 - fromx);
                                var dy_temp = Math.abs(y2 - fromy);
                                var L = Math.sqrt(dx_temp * dx_temp + dy_temp * dy_temp);
                                //получение х и у нужного отклоненного угла
                                var newx = k * L * Math.cos(alfa);
                                var newy = k * L * Math.sin(alfa);

                                //подсчет и построение линии отклоненного угла (луча)
                                x2 = fromx + newx;
                                y2 = fromy + newy;
                                dx1 = x2 - fromx;
                                dy1 = y2 - fromy;
                                angle1 = Math.atan2(dy1, dx1);
                                context.beginPath();
                                context.moveTo(fromx, fromy);
                                context.lineTo(x2, y2);
                                context.stroke();

                                if (point_model.count < 2) {//если меньше 2-х точек на карте, то дальнейший подсчет не нужен
                                    mapFrame.crossingX = -1;
                                    mapFrame.crossingY = -1;
                                    mapFrame.distance_fromP1 = -1;
                                    mapFrame.distance_fromP2 = -1;
                                    return;
                                }

                                //КОСТЫЛЬ ДЛЯ 2х МОДУЛЕЙ
                                //работает только с первым и вторым модулями!!!
                                var X1 = point_model.get(0).xpos;
                                var Y1 = point_model.get(0).ypos;

                                var X2 = point_model.get(1).xpos;
                                var Y2 = point_model.get(1).ypos;

                                var m = 1/Math.tan(modelView.angles.get(0).angle/180*Math.PI);
                                var n = 1/Math.tan(modelView.angles.get(1).angle/180*Math.PI);

                                ///точка пересечения
                                var x = (m * X1 + Y1 - Y2 - n * X2)/(m-n);
                                var y = -m*(x - X1) + Y1;

                                var new_alfa1 = modelView.angles.get(0).angle;
                                var new_alfa2 = modelView.angles.get(1).angle;

                                var first_ray_toTop = new_alfa1 < 90 || new_alfa1 > 270 ? true : false;//смотрит ли первый луч "наверх"
                                var second_ray_toTop = new_alfa2 < 90 || new_alfa2 > 270 ? true : false;//смотрит ли второй луч "наверх"
                                var is_crossing_point_real = true;

                                //////////////////////////////////////////////////////////////////////////////////////////////////
                                //////сейчас есть небольшая ошибка, когда один из лучей отклоняется на 0 или 180 градусов, то точка пересечения не показывается
                                //////так же и для 90градусов, точка пересечения показывается только для случая, когда один из лучей отклонен на 270 градусов
                                //////////////////////////////////////////////////////////////////////////////////////////////////

                                //если первый луч смотрит вверх и точка пересечения лежит ниже начала луча
                                if (first_ray_toTop && y > Y1) is_crossing_point_real = false;
                                //если второй луч смотрит вверх и точка пересечения лежит ниже начала луча
                                if (second_ray_toTop && y > Y2) is_crossing_point_real = false;
                                //если первый луч смотрит вниз и точка пересечения лежит выше начала луча
                                if (!first_ray_toTop && y <= Y1) is_crossing_point_real = false;
                                //если второй луч смотрит вверх и точка пересечения лежит ниже начала луча
                                if (!second_ray_toTop && y <= Y2) is_crossing_point_real = false;

                                //поменяем цвет точки пересечения на противоположный от самого контрастного
                                var color = colorDialog.color;
                                var max_color = Math.max(color.r, color.g, color.b);
                                if (max_color === color.r) color = "#00FFFF";
                                if (max_color === color.g) color = "#FF00FF";
                                if (max_color === color.b) color = "#FFFF00";
                                context.strokeStyle = color;

                                //трекинг: если он активирован, то рисуем добавленные точки пересечения
                                if (btn_tracking.isTracking) {
                                    context.fillStyle = color;
                                    for(var i = 0; i < modelView.points.count; i++) {//рисование прошлых точек пересечения
                                        context.beginPath();
                                        var radius = mapImage.scale < 1.0 ? 3 : 4/mapImage.scale; //меняем радиус в зависимости от масштаба карты
                                        context.arc(modelView.points.get(i).x, modelView.points.get(i).y, radius, 0, 2 * Math.PI);
                                        context.fill();
                                        context.stroke();
                                    }
                                }


                                var propX = Math.abs(x)/mapImage.width;
                                var propY = Math.abs(y)/mapImage.height;

                                //если точка пересечения лежит за пределами карты, то не показываем его на карте
                                if(x < 0 || y < 0 || x > mapImage.width || y > mapImage.height) {
                                    mapFrame.crossingX = -1;
                                    mapFrame.crossingY = -1;
                                }
                                else {

                                    mapFrame.crossingX = (mapFrame.zeroPointLongitude + mapFrame.deltaFullLongitude*propX).toFixed(5);
                                    mapFrame.crossingY = (mapFrame.zeroPointLatitude - mapFrame.deltaFullLatitude*propY).toFixed(5);

                                    //получаем координаты 2-х модулей
                                    var p1X = (mapFrame.zeroPointLongitude + mapFrame.deltaFullLongitude*X1/mapImage.width).toFixed(5);
                                    var p1Y = (mapFrame.zeroPointLatitude - mapFrame.deltaFullLatitude*Y1/mapImage.height).toFixed(5);
                                    var p2X = (mapFrame.zeroPointLongitude + mapFrame.deltaFullLongitude*X2/mapImage.width).toFixed(5);
                                    var p2Y = (mapFrame.zeroPointLatitude - mapFrame.deltaFullLatitude*Y2/mapImage.height).toFixed(5);
                                    //вычисляем дистанцию
                                    mapFrame.distance_fromP1 = (getDistance(p1Y, p1X, mapFrame.crossingY, mapFrame.crossingX)).toFixed(1);
                                    mapFrame.distance_fromP2 = (getDistance(p2Y, p2X, mapFrame.crossingY, mapFrame.crossingX)).toFixed(1);
                                }

                                //проверка на валидность точек и точки пересечения лучей
                                if (modelView.angles.get(0).flag === false || modelView.angles.get(1).flag === false || !is_crossing_point_real) {
                                    mapFrame.crossingX = -1;
                                    mapFrame.crossingY = -1;
                                    mapFrame.distance_fromP1 = -1;
                                    mapFrame.distance_fromP2 = -1;
                                    return;
                                }

                                if (btn_tracking.isTracking) modelView.points.append({ "x": x, "y": y });

                                //рисование точки пересечения
                                context.beginPath();
                                radius = mapImage.scale < 1.0 ? 3 : 4/mapImage.scale; //меняем радиус в зависимости от масштаба карты
                                context.arc(x, y, radius, 0, 2 * Math.PI);
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
                                //Получаем контекст рамки
                                if (point_model.count === 0) return;
                                var ctx = getContext("2d");
                                ctx.reset();

                                var x_zero = model.xpos;
                                var y_zero = model.ypos;

                                draw_All_Elements(ctx, x_zero, y_zero, x_zero, y_zero);
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
                                    modelView.points.clear();
                                    point_model.remove(index);
                                }
                            }
                        }
                    }

                    Settings {
                        id: settings
                        property alias datastore: rootItem.datastore
                        property alias map_index: rootItem.map_index
                        property alias color: rootItem.color
                    }
                }
            }

            Text {
                id: textMouseX
                text: "X: " + mapFrame.mouseXCoordinate
                color: colorDialog.color
                anchors.bottom: textMouseY.top
                anchors.left: parent.left
                anchors.margins: 5
                font.pointSize: 11
            }

            Text {
                id: textMouseY
                text: "Y: " + mapFrame.mouseYCoordinate
                color: colorDialog.color
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
                    color: btn_color_choosing.down ? rootItem.color : colorDialog.color
                }

                onClicked: {
                    colorDialog.open();
                }
            }

            Button {
                id: btn_tracking
                property bool isTracking: false
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                text: !isTracking? "▶" : "⏹"
                background: Rectangle {
                    border.width: !btn_tracking.isTracking? 1 : 3
                    border.color: !btn_tracking.isTracking? "black" : "lightblue"
                    color: !btn_tracking.isTracking? "lightgray" : "gray"
                    radius: 10
                    opacity: 0.6
                }
                onClicked: {
                    isTracking = !isTracking;

                    if (!isTracking) {
//                        grabToImage()

                        modelView.points.clear();
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
                    border.color: "grey"
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
                    border.color: "grey"
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
                        border.color: "grey"
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

import QtQuick 2.12
import QtQml 2.12
import QtQuick.Window 2.15
import QtQuick.Controls 1.4
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import Qt.labs.qmlmodels 1.0

//Форма для диалогового окна для добавления карты
Rectangle {
    id: dialogMapAddingRoot

    implicitHeight: 410
    implicitWidth: 300

    property int fontSize: 9
    property int heightElements: 25
    property int spacingValue: 10
    property int spacingBetweenElements: 5
    property int widthForInput: 180

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: dialogMapAddingRoot.spacingValue

        Label {
            Layout.minimumWidth: dialogMapAddingRoot.widthForInput
            font.pointSize: 9
            text: "Введите название карты"
        }
        Rectangle {
            height: dialogMapAddingRoot.heightElements
            Layout.fillWidth: true
            Layout.minimumWidth: dialogMapAddingRoot.widthForInput
            border.width: 1
            TextInput {
                id: textInputMapName
                anchors.fill: parent
                font.pointSize: 12
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                leftPadding: 5
                maximumLength: 30
            }
        }

        Label {
            font.pointSize: 9
            text: "Введите координаты левого вверхнего угла\nв десятичных градусах"
        }

        RowLayout {
            Label {
                id: lbl_latitude1
                font.pointSize: 9
                text: "Широта:"
            }
            Rectangle {
                height: dialogMapAddingRoot.heightElements
                Layout.fillWidth: true
                Layout.minimumWidth: dialogMapAddingRoot.widthForInput
                border.width: 1
                TextInput {
                    id: topLeftLatitude
                    anchors.fill: parent
                    font.pointSize: 12
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    leftPadding: 5
                    maximumLength: 12

                    validator: DoubleValidator { locale: "." }
                }
            }
            Label {
                font.pointSize: 9
                text: "°N"
            }
        }

        RowLayout {

            Label {
                font.pointSize: 9
                text: "Долгота:"
            }
            Rectangle {
                height: dialogMapAddingRoot.heightElements
                Layout.fillWidth: true
                Layout.minimumWidth: dialogMapAddingRoot.widthForInput
                border.width: 1
                TextInput {
                    id: topLeftLongitude
                    anchors.fill: parent
                    font.pointSize: 12
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    leftPadding: 5
                    maximumLength: 12

                    validator: DoubleValidator { locale: "." }
                }
            }
            Label {
                font.pointSize: 9
                text: "°E"
            }
        }

        Label {
            font.pointSize: 9
            text: "Введите координаты правого нижнего угла\nв десятичных градусах"
        }

        RowLayout {
            Label {
                font.pointSize: 9
                text: "Широта:"
            }
            Rectangle {
                height: dialogMapAddingRoot.heightElements
                Layout.fillWidth: true
                Layout.minimumWidth: dialogMapAddingRoot.widthForInput
                border.width: 1
                TextInput {
                    id: bottomRightLatitude
                    anchors.fill: parent
                    font.pointSize: 12
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    leftPadding: 5
                    maximumLength: 12

                    validator: DoubleValidator { locale: "." }
                }
            }
            Label {
                font.pointSize: 9
                text: "°N"
            }
        }

        RowLayout {
            Label {
                font.pointSize: 9
                text: "Долгота:"
            }
            Rectangle {
                height: dialogMapAddingRoot.heightElements
                Layout.fillWidth: true
                Layout.minimumWidth: dialogMapAddingRoot.widthForInput
                border.width: 1
                TextInput {
                    id: bottomRightLongitude
                    anchors.fill: parent
                    font.pointSize: 12
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    leftPadding: 5
                    maximumLength: 12

                    validator: DoubleValidator { locale: "." }
                }
            }
            Label {
                font.pointSize: 9
                text: "°E"
            }
        }

        Button {
            font.pointSize: 9
            Layout.fillWidth: true
            text: "Укажите файл карты..."
            onClicked: { fileDialogForMap.open(); }

            FileDialog {
                id: fileDialogForMap
                title: "Выберите файл с картой"
                nameFilters: ["PNG files (*.png)", "JPG files (*.jpg)"]

                onAccepted: {
                    var array = fileUrl.toString().split('/');
                    var mapName = array[array.length - 1];
//                    console.log("Вы выбрали: " + (array[array.length - 1]));
                    labelPath.text = "Вы выбрали:  .../" + mapName;
                }
            }
        }

        Label {
            id: labelPath
            font.pointSize: 9
        }

        RowLayout {
            Button {
                Layout.fillWidth: true
                text: "Установить"
                onClicked: {
                    if(labelPath.text === ""){
                        messageDialog.text = "Вы не выбрали файл с картой!";
                        messageDialog.open();
                        return;
                    }

                    if (textInputMapName.text === "" || topLeftLatitude.text === "" || topLeftLongitude.text === "" ||
                            bottomRightLatitude.text === "" || bottomRightLongitude.text === "") {
                        messageDialog.text = "Остались незаполненные поля!";
                        messageDialog.open();
                        return;
                    }

                    if (parseFloat(topLeftLatitude.text) < 0 || parseFloat(topLeftLatitude.text) > 90) {
                        messageDialog.text = "Введенное значение широты левого верхнего угла лежит за пределами от 0° до 90°";
                        messageDialog.open();
                        return;
                    }
                    if (parseFloat(topLeftLongitude.text) < 0 || parseFloat(topLeftLongitude.text) > 180) {
                        messageDialog.text = "Введенное значение долготы левого верхнего угла лежит за пределами от 0° до 180°";
                        messageDialog.open();
                        return;
                    }
                    if (parseFloat(bottomRightLatitude.text) < 0 || parseFloat(bottomRightLatitude.text) > 90) {
                        messageDialog.text = "Введенное значение широты правого нижнего угла лежит за пределами от 0° до 90°";
                        messageDialog.open();
                        return;
                    }
                    if (parseFloat(bottomRightLongitude.text) < 0 || parseFloat(bottomRightLongitude.text) > 180) {
                        messageDialog.text = "Введенное значение долготы правого нижнего угла лежит за пределами от 0° до 180°";
                        messageDialog.open();
                        return;
                    }

                    if(parseFloat(topLeftLatitude.text) < parseFloat(bottomRightLatitude.text)) {
                        messageDialog.text = "Значение широты левого верхнего угла не может быть меньше широты в правом нижнем углу";
                        messageDialog.open();
                        return;
                    }

                    if(parseFloat(topLeftLongitude.text) > parseFloat(bottomRightLongitude.text)) {
                        messageDialog.text = "Значение долготы левого верхнего угла не может быть больше долготы в правом нижнем углу";
                        messageDialog.open();
                        return;
                    }

                    modelView.addNewMap(textInputMapName.text, topLeftLatitude.text,
                                           topLeftLongitude.text, bottomRightLatitude.text,
                                           bottomRightLongitude.text, fileDialogForMap.fileUrl);
                    dialogAddMap.close();
                }
            }

            Button {
                text: "Отмена"
                onClicked: dialogAddMap.close();
            }

            MessageDialog {
                id: messageDialog
                onButtonClicked: { close(); }
            }
        }
    }
}

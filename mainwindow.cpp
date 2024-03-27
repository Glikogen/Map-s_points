#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "QQuickWidget"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    qmlRegisterType<ModelView>("ModelView", 1, 0, "ModelView");

    ui->quickWidget->setSource(QUrl("qrc:/main_map.qml"));
    ui->quickWidget->show();
    QObject *rootObj =qobject_cast<QObject*>(ui->quickWidget->rootObject());

    //сигнал-слот для отправки alfa1 и alfa2 на модельвью
    connect(ui->pb_show_angles, &QPushButton::clicked, [=]() {
        emit sendAngles(ui->le_alfa1->text().toDouble(), ui->le_alfa2->text().toDouble());
    });

    connect(this, &MainWindow::sendAngles, [=](QVariant angle1, QVariant angle2) {
        qDebug() << "angle1 = " + angle1.toString() + "; angle2 = " + angle2.toString();
        QMetaObject::invokeMethod(rootObj, "setAngles", Q_ARG(QVariant, angle1), Q_ARG(QVariant, angle2));
    });
}

MainWindow::~MainWindow()
{
    delete ui;
}


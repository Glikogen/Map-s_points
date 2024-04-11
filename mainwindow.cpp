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
    QObject *rootObj = qobject_cast<QObject*>(ui->quickWidget->rootObject());

    //углы для теста
    angles = {{10, -20, 999, 90},
              {10, -20, 999, 90},
              {10, -20, 999, 90},
              {10, -20, 999, 90},
              {10, -20, 999, 90},
              {10, -20, 999, 90},
              {10, -20, 999, 90},
              {10, -20, 999, 90}};

//    angles = {{45, 999, 999, 90},
//              {45, 999, 999, 90},
//              {45, 999, 999, 90},
//              {45, 999, 999, 90},
//              {45, 999, 999, 90},
//              {45, 999, 999, 90},
//              {45, 999, 999, 90},
//              {45, 999, 999, 90}};

    //смещения для теста
    offsets = {{0, 0, 0, 999},
              {0, 0, 0, 999},
              {0, 0, 0, 999},
              {0, 0, 0, 999},
              {0, 0, 0, 999},
              {0, 0, 0, 999},
              {0, 0, 0, 999},
              {0, 0, 0, 999}};
    QTimer *timer = new QTimer();
    timer->setInterval(1000);
    connect(timer, &QTimer::timeout, [=]() {
        emit sendAngle(QVariant::fromValue(angles[i]), QVariant::fromValue(offsets[i]));
    });
    connect(timer, &QTimer::timeout, this, &MainWindow::changeTestAnglesIndex);
    timer->start();

    connect(this, &MainWindow::sendAngle, [=](QVariant angle, QVariant bias) {
        QMetaObject::invokeMethod(rootObj, "setAngles", Q_ARG(QVariant, angle), Q_ARG(QVariant, bias));
    });
}


void MainWindow::changeTestAnglesIndex()
{
    i++;
    if (i == angles.count()) i = 0;
}

MainWindow::~MainWindow()
{
    delete ui;
}


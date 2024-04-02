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
    angles = {{30, 270, 45, 90},
              {40, 280, 55, 100},
              {50, 290, 65, 110},
              {60, 300, 75, 120},
              {70, 310, 85, 130},
              {80, 320, 95, 140},
              {90, 330, 105, 150},
              {100, 340, 115, 125}};
    QTimer *timer = new QTimer();
    timer->setInterval(1000);
    connect(timer, &QTimer::timeout, [=]() {
        emit sendAngle(QVariant::fromValue(angles[i]), ui->le_bias->text().toDouble());
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


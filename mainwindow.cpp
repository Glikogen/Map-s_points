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
    QObject *rootObj = qobject_cast<QObject*>(ui->quickWidget->rootObject()); //получаем корневой элемент qml формы

    ////test
    //углы для теста, первый модуль заполняется от 0 до 359, второй всегда 315
    int amount = 360;
    int stepSize = 10;//можно менять этот параметр, тогда скачок угла будет stepSize
    //делю amount на stepSize получаю количество углов
    angles = QVector<QVector<double>>(amount/stepSize);
    for(int k = 0; k < amount/stepSize; k++){
        int koef = stepSize; //это чтобы задать конкретный угол
        int val = k * koef;
        angles[k] = QVector<double>{static_cast<double>(val), 315};
    }
    //смещения, заполняется нулями
    offsets = QVector<QVector<double>>(amount/stepSize);
    for(int k = 0; k < amount/stepSize; k++) { offsets[k] = QVector<double>(2); }
    ////test

    //тут происходит отправление углов и смещений по тику таймера
    QTimer *timer = new QTimer();
    timer->setInterval(500);
    if (angles.count() > 0 && offsets.count() > 0) connect(timer, &QTimer::timeout, [=]() {
        emit sendAngle(QVariant::fromValue(angles[i]), QVariant::fromValue(offsets[i]));
    });
    connect(timer, &QTimer::timeout, this, &MainWindow::changeTestAnglesIndex);
    timer->start();

    //тут сигнал с отправленными углами привязывается к функции из main_map.qml
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


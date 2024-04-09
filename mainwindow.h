#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include "modelview.h"
#include <QMetaObject>
#include <QtQuick>
#include <QVector>
#include <QTimer>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

    int i = 0;
    QVector<QVector<double>> angles;
    QVector<QVector<double>> offsets;
signals:
    void sendAngle(QVariant, QVariant);
public slots:
    void changeTestAnglesIndex();
private:
    Ui::MainWindow *ui;
};
#endif // MAINWINDOW_H

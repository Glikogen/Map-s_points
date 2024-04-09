#include "mainwindow.h"

#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    a.setOrganizationName("NIO-5");
    a.setOrganizationDomain("VNIIFTRI");
    a.setApplicationName("Map_with_qml");

    MainWindow w;
    w.show();
    return a.exec();
}

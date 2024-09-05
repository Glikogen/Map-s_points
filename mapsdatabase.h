#ifndef MAPSDATABASE_H
#define MAPSDATABASE_H

#include <QObject>
#include <QtSql>

//Класс для добавляемых карт, сохраняемых в базу данных
class MapImageData : public QObject {
    Q_OBJECT
public:
    int ID;
    QString MapName;
    qreal Top_left_latitude;
    qreal Top_left_longitude;
    qreal Bottom_right_latitude;
    qreal Bottom_right_longitude;
    QString PathToImage;
};

//Класс-обертка для базы данных для добавленных карт
class MapsDataBase : public QObject
{
    Q_OBJECT
public:
    explicit MapsDataBase(QObject *parent = nullptr);
    QStringList mapNames;
    MapImageData *getData(int id);
    void addData(MapImageData* data);
    void deleteData(int id);
signals:

private:
    bool ConnectToDB();
    void CreateTable();
    void getAllMaps();
signals:

};

#endif // MAPSDATABASE_H

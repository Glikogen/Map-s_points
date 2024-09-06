#include "mapsdatabase.h"

MapsDataBase::MapsDataBase(QObject *parent) : QObject(parent)
{
//    QSqlDatabase::removeDatabase("mapImages.db");
//    return;
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "SQLITE");
    //проверяем на наличие sqlite на компе
    if (!QSqlDatabase::drivers().contains("QSQLITE"))
        qDebug() << "Unable to load database; This programm needs the SQLITE driver";

    if(!ConnectToDB())
    {
        return;
    }

    getAllMaps();
}

MapImageData *MapsDataBase::getData(int id)
{
    MapImageData *mapImageData = nullptr;
    id++;//увеличиваем на 1, так как PRIMARY KEY начинается с 1

    //вытянусть с базы данных инфу и засунуть в объект
    QSqlQuery query(QSqlDatabase::database("mapImages1.db"));
    QString strF = "SELECT * from Maps WHERE ID=%1";
    QString str = strF.arg(id);
    if (!query.exec(str)) {
        qDebug() << "Не удалось получить строку с id=" << id << ";" << query.lastError();
        return mapImageData;
    }
    mapImageData = new MapImageData;
    QSqlRecord rec = query.record();
    query.first();
    mapImageData->MapName = query.value(rec.indexOf("MapName")).toString();
    mapImageData->Top_left_latitude = query.value(rec.indexOf("Top_left_latitude")).toReal();
    mapImageData->Top_left_longitude = query.value(rec.indexOf("Top_left_longitude")).toReal();
    mapImageData->Bottom_right_latitude = query.value(rec.indexOf("Bottom_right_latitude")).toReal();
    mapImageData->Bottom_right_longitude = query.value(rec.indexOf("Bottom_right_longitude")).toReal();
    mapImageData->PathToImage = query.value(rec.indexOf("PathToImage")).toString();
    qDebug() << mapImageData->MapName << " " << mapImageData->Top_left_latitude << " " << mapImageData->Top_left_longitude;
    qDebug() << mapImageData->Bottom_right_latitude << " " << mapImageData->Bottom_right_longitude << " " << mapImageData->PathToImage;

    return mapImageData;
}

void MapsDataBase::addData(MapImageData *data)
{
    //добавить строчку в базу данных
    QSqlQuery query(QSqlDatabase::database("mapImages1.db"));
    QString strF = "INSERT INTO Maps (MapName, Top_left_latitude, Top_left_longitude, Bottom_right_latitude, Bottom_right_longitude, PathToImage)"
        "VALUES('%1', '%2', '%3', '%4', '%5', '%6');";
    QString str = strF.arg(data->MapName).arg(data->Top_left_latitude).arg(data->Top_left_longitude)
            .arg(data->Bottom_right_latitude).arg(data->Bottom_right_longitude).arg(data->PathToImage);
    if(!query.exec(str)) {
        qDebug() << "Unable to insert " << data->MapName + ": " << query.lastError();
        return;
    }

    getAllMaps();
}

void MapsDataBase::deleteData(int id)
{
    id++;//увеличиваем на 1, так как PRIMARY KEY начинается с 1
    QSqlQuery query(QSqlDatabase::database("mapImages1.db"));
    QString strF = "DELETE FROM Maps WHERE ID=%1;";
    QString str = strF.arg(id);
    if (!query.exec(str)) {
        qDebug() << "Не удалось удалить строку с id=" << id << ";" << query.lastError();
        return;
    }
    getAllMaps();
}

bool MapsDataBase::ConnectToDB()
{
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName("mapImages1.db");

    if(db.isOpen()) return true;
    if (!db.open())
    {
        qDebug() << "Cannot open db: " << db.lastError();
        return false;
    }

    //проверяем на наличие таблиц перед их созданием
    QStringList tables = db.tables();
    if (!tables.contains("Maps", Qt::CaseInsensitive))
        CreateTable();

    return true;
}

void MapsDataBase::CreateTable()
{
    QSqlQuery query(QSqlDatabase::database("mapImages1.db"));
    QString str = "CREATE TABLE Maps ( "
                    "ID INTEGER NOT NULL PRIMARY KEY, "
                    "MapName VARCHAR(50), "
                    "Top_left_latitude VARCHAR(50), "
                    "Top_left_longitude VARCHAR(50), "
                    "Bottom_right_latitude VARCHAR(50), "
                    "Bottom_right_longitude VARCHAR(50), "
                    "PathToImage VARCHAR(150) "
                    ");";
    if (!query.exec(str)) { qDebug() << "Unable to create maps " << query.lastError(); }

    QString strF = "INSERT INTO Maps (MapName, Top_left_latitude, Top_left_longitude, Bottom_right_latitude, Bottom_right_longitude, PathToImage) VALUES('%1', '%2', '%3', '%4', '%5', '%6');";
    str = strF.arg("ВНИИФТРИ").arg("56.0474995832989").arg("37.177734375").arg("55.9984769510856").arg("37.309398651123").arg("qrc:/VNIIFTRI.png");
    if(!query.exec(str)){ qDebug() << "Unable to insert vniiftri: " << query.lastError(); }
//    str = strF.arg("УМБА1").arg("67.0674333474637").arg("31.9921875").arg("64.1684060861894").arg("40.6047821044922").arg("qrc:/umba.png");
//    if(!query.exec(str)) { qDebug() << "Unable to insert umba1: " << query.lastError(); }
}

void MapsDataBase::getAllMaps()
{
    mapNames.clear();
    QSqlQuery query(QSqlDatabase::database("mapImages1.db"));
    QString strF = "SELECT * from Maps";
    if (!query.exec(strF)) {
        qDebug() << "Не удалось получить данные из таблицы Maps" << query.lastError();
        return;
    }
    QSqlRecord rec = query.record();
    while(query.next()){
        mapNames.append(query.value(rec.indexOf("MapName")).toString());
        qDebug() << query.value(rec.indexOf("ID")).toInt();
    }
}

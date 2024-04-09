#include "modelview.h"

ModelView::ModelView(QObject *parent) : QObject(parent)
{
    mapsDataBase = new MapsDataBase;
    setmapNames(mapsDataBase->mapNames);


}

void ModelView::addNewMap(QString Name, QString TopLeftLatitude, QString TopLeftLongitude, QString BottomRightLatitude, QString BottomRightLongitude, QString path)
{
    if (path.contains("file:///")) path = path.right(path.length() - 8);

    QString newPath = QDir::currentPath() + "/" + Name + ".png";//мб .jpeg надо еще предусмотреть
    QFile::copy(path,newPath);//копируем картинку в директорию проекта

    MapImageData *mapImageData = new MapImageData;
    mapImageData->MapName = Name;
    mapImageData->Top_left_latitude = TopLeftLatitude.toDouble();
    mapImageData->Top_left_longitude = TopLeftLongitude.toDouble();
    mapImageData->Bottom_right_latitude = BottomRightLatitude.toDouble();
    mapImageData->Bottom_right_longitude = BottomRightLongitude.toDouble();
    mapImageData->PathToImage = newPath;

    qDebug() << "Top_left_longitude = " << mapImageData->Top_left_longitude;
    qDebug() << "Bottom_right_longitude = " << mapImageData->Bottom_right_longitude;

    mapsDataBase->addData(mapImageData);
    setmapNames(mapsDataBase->mapNames);
}

void ModelView::deleteCurrentMap(int id)
{
    MapImageData *mid = mapsDataBase->getData(id);
    //подумать как удалять из папки проекта
    mapsDataBase->deleteData(id);
    setmapNames(mapsDataBase->mapNames);
}

void ModelView::currentMapChanged(int id)
{
    MapImageData *mid = mapsDataBase->getData(id);
    if (!mid->PathToImage.contains("qrc:")) mid->PathToImage = "file:///" + mid->PathToImage;
    emit sendMapImageData(mid->MapName, mid->Top_left_latitude, mid->Top_left_longitude, mid->Bottom_right_latitude, mid->Bottom_right_longitude, mid->PathToImage);
}


const QStringList &ModelView::mapNames() const
{
    return m_mapNames;
}

void ModelView::setmapNames(const QStringList &newMapNames)
{
    if (m_mapNames == newMapNames)
        return;
    m_mapNames = newMapNames;
    emit mapNamesChanged();
}

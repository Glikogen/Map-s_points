#ifndef MODELVIEW_H
#define MODELVIEW_H

#include <QObject>
#include <QStringListModel>
#include <QTimer>
#include <QMessageBox>
#include <QFileDialog>
#include <QInputDialog>
#include <QFile>
#include <QDateTime>
#include <QIODevice>
#include <QTextStream>
#include <QSettings>
#include <QResource>
#include "mapsdatabase.h"

class ModelView : public QObject
{
    Q_OBJECT
public:
    explicit ModelView(QObject *parent = nullptr);

    Q_PROPERTY(QStringList mapNames READ mapNames WRITE setmapNames NOTIFY mapNamesChanged)
    const QStringList &mapNames() const;
    void setmapNames(const QStringList &newMapNames);

private:
    MapsDataBase *mapsDataBase;
    QStringList m_mapNames;

public slots:
    void addNewMap(QString Name, QString TopLeftLatitude, QString TopLeftLongitude, QString BottomRightLatitude, QString BottomRightLongitude, QString path);
    void deleteCurrentMap(int id);
    void currentMapChanged(int id);
signals:
    void sendMapImageData(QString, double, double, double, double, QString);
    void mapNamesChanged();
};

#endif // MODELVIEW_H

#include "downloadmanager.h"

#include <QFileInfo>
#include <QDateTime>
#include <QDebug>


DownloadManager::DownloadManager(QObject *parent) :
    QObject(parent)
    , _pHTTP(NULL)
{
}


void DownloadManager::download(QUrl url)
{
    qDebug() << __FUNCTION__ << "(" << url.toString() << ")";

    _URL = url;

    {
        _pHTTP = new DownloadManager(this);

        connect(_pHTTP, SIGNAL(addLine(QString)), this, SLOT(localAddLine(QString)));
        connect(_pHTTP, SIGNAL(progress(int)), this, SLOT(localProgress(int)));
        connect(_pHTTP, SIGNAL(downloadComplete()), this, SLOT(localDownloadComplete()));

        _pHTTP->download(_URL);
    }
}


void DownloadManager::pause()
{
    qDebug() << __FUNCTION__;

    {
        _pHTTP->pause();
    }
}


void DownloadManager::resume()
{
    qDebug() << __FUNCTION__;

    {
        _pHTTP->resume();
    }
}


void DownloadManager::localAddLine(QString qsLine)
{
    emit addLine(qsLine);
}


void DownloadManager::localProgress(int nPercentage)
{
    emit progress(nPercentage);
}


void DownloadManager::localDownloadComplete()
{
    emit downloadComplete();
}

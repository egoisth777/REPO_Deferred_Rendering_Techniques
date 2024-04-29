/********************************************************************************
** Form generated from reading UI file 'mainwindow.ui'
**
** Created by: Qt User Interface Compiler version 6.2.2
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtWidgets/QApplication>
#include <QtWidgets/QDoubleSpinBox>
#include <QtWidgets/QLabel>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenu>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSlider>
#include <QtWidgets/QWidget>
#include "mygl.h"

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QAction *actionQuit;
    QAction *actionCamera_Controls;
    QWidget *centralWidget;
    MyGL *mygl;
    QSlider *metallicSlider;
    QLabel *label;
    QLabel *label_2;
    QSlider *roughnessSlider;
    QSlider *aoSlider;
    QLabel *label_3;
    QSlider *redSlider;
    QSlider *greenSlider;
    QSlider *blueSlider;
    QLabel *label_4;
    QLabel *label_5;
    QLabel *label_6;
    QLabel *label_7;
    QPushButton *envMapButton;
    QPushButton *sceneButton;
    QPushButton *sphereButton;
    QLabel *label_8;
    QDoubleSpinBox *displacementSpinBox;
    QPushButton *objButton;
    QMenuBar *menuBar;
    QMenu *menuFile;
    QMenu *menuHelp;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName(QString::fromUtf8("MainWindow"));
        MainWindow->resize(902, 612);
        actionQuit = new QAction(MainWindow);
        actionQuit->setObjectName(QString::fromUtf8("actionQuit"));
        actionCamera_Controls = new QAction(MainWindow);
        actionCamera_Controls->setObjectName(QString::fromUtf8("actionCamera_Controls"));
        centralWidget = new QWidget(MainWindow);
        centralWidget->setObjectName(QString::fromUtf8("centralWidget"));
        mygl = new MyGL(centralWidget);
        mygl->setObjectName(QString::fromUtf8("mygl"));
        mygl->setGeometry(QRect(11, 11, 618, 561));
        mygl->setBaseSize(QSize(512, 512));
        metallicSlider = new QSlider(centralWidget);
        metallicSlider->setObjectName(QString::fromUtf8("metallicSlider"));
        metallicSlider->setGeometry(QRect(640, 290, 160, 18));
        metallicSlider->setMinimum(0);
        metallicSlider->setMaximum(100);
        metallicSlider->setValue(50);
        metallicSlider->setOrientation(Qt::Horizontal);
        label = new QLabel(centralWidget);
        label->setObjectName(QString::fromUtf8("label"));
        label->setGeometry(QRect(650, 260, 63, 20));
        label_2 = new QLabel(centralWidget);
        label_2->setObjectName(QString::fromUtf8("label_2"));
        label_2->setGeometry(QRect(650, 320, 91, 20));
        roughnessSlider = new QSlider(centralWidget);
        roughnessSlider->setObjectName(QString::fromUtf8("roughnessSlider"));
        roughnessSlider->setGeometry(QRect(640, 350, 160, 18));
        roughnessSlider->setMinimum(0);
        roughnessSlider->setMaximum(100);
        roughnessSlider->setValue(50);
        roughnessSlider->setOrientation(Qt::Horizontal);
        aoSlider = new QSlider(centralWidget);
        aoSlider->setObjectName(QString::fromUtf8("aoSlider"));
        aoSlider->setGeometry(QRect(640, 410, 160, 18));
        aoSlider->setMinimum(0);
        aoSlider->setMaximum(100);
        aoSlider->setValue(100);
        aoSlider->setOrientation(Qt::Horizontal);
        label_3 = new QLabel(centralWidget);
        label_3->setObjectName(QString::fromUtf8("label_3"));
        label_3->setGeometry(QRect(650, 380, 131, 20));
        redSlider = new QSlider(centralWidget);
        redSlider->setObjectName(QString::fromUtf8("redSlider"));
        redSlider->setGeometry(QRect(650, 80, 18, 160));
        redSlider->setMaximum(100);
        redSlider->setValue(50);
        redSlider->setOrientation(Qt::Vertical);
        greenSlider = new QSlider(centralWidget);
        greenSlider->setObjectName(QString::fromUtf8("greenSlider"));
        greenSlider->setGeometry(QRect(700, 80, 18, 160));
        greenSlider->setMaximum(100);
        greenSlider->setOrientation(Qt::Vertical);
        blueSlider = new QSlider(centralWidget);
        blueSlider->setObjectName(QString::fromUtf8("blueSlider"));
        blueSlider->setGeometry(QRect(750, 80, 18, 160));
        blueSlider->setMaximum(100);
        blueSlider->setOrientation(Qt::Vertical);
        label_4 = new QLabel(centralWidget);
        label_4->setObjectName(QString::fromUtf8("label_4"));
        label_4->setGeometry(QRect(650, 50, 21, 20));
        label_5 = new QLabel(centralWidget);
        label_5->setObjectName(QString::fromUtf8("label_5"));
        label_5->setGeometry(QRect(700, 50, 31, 20));
        label_6 = new QLabel(centralWidget);
        label_6->setObjectName(QString::fromUtf8("label_6"));
        label_6->setGeometry(QRect(750, 50, 21, 20));
        label_7 = new QLabel(centralWidget);
        label_7->setObjectName(QString::fromUtf8("label_7"));
        label_7->setGeometry(QRect(650, 20, 63, 20));
        envMapButton = new QPushButton(centralWidget);
        envMapButton->setObjectName(QString::fromUtf8("envMapButton"));
        envMapButton->setGeometry(QRect(680, 460, 161, 29));
        sceneButton = new QPushButton(centralWidget);
        sceneButton->setObjectName(QString::fromUtf8("sceneButton"));
        sceneButton->setGeometry(QRect(650, 500, 91, 29));
        sphereButton = new QPushButton(centralWidget);
        sphereButton->setObjectName(QString::fromUtf8("sphereButton"));
        sphereButton->setGeometry(QRect(750, 520, 121, 29));
        label_8 = new QLabel(centralWidget);
        label_8->setObjectName(QString::fromUtf8("label_8"));
        label_8->setGeometry(QRect(800, 260, 101, 20));
        displacementSpinBox = new QDoubleSpinBox(centralWidget);
        displacementSpinBox->setObjectName(QString::fromUtf8("displacementSpinBox"));
        displacementSpinBox->setGeometry(QRect(820, 290, 67, 29));
        displacementSpinBox->setSingleStep(0.100000000000000);
        displacementSpinBox->setValue(0.200000000000000);
        objButton = new QPushButton(centralWidget);
        objButton->setObjectName(QString::fromUtf8("objButton"));
        objButton->setGeometry(QRect(650, 540, 91, 29));
        MainWindow->setCentralWidget(centralWidget);
        menuBar = new QMenuBar(MainWindow);
        menuBar->setObjectName(QString::fromUtf8("menuBar"));
        menuBar->setGeometry(QRect(0, 0, 902, 25));
        menuFile = new QMenu(menuBar);
        menuFile->setObjectName(QString::fromUtf8("menuFile"));
        menuHelp = new QMenu(menuBar);
        menuHelp->setObjectName(QString::fromUtf8("menuHelp"));
        MainWindow->setMenuBar(menuBar);

        menuBar->addAction(menuFile->menuAction());
        menuBar->addAction(menuHelp->menuAction());
        menuFile->addAction(actionQuit);
        menuHelp->addAction(actionCamera_Controls);

        retranslateUi(MainWindow);

        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QCoreApplication::translate("MainWindow", "Physically-Based Shaders", nullptr));
        actionQuit->setText(QCoreApplication::translate("MainWindow", "Quit", nullptr));
#if QT_CONFIG(shortcut)
        actionQuit->setShortcut(QCoreApplication::translate("MainWindow", "Ctrl+Q", nullptr));
#endif // QT_CONFIG(shortcut)
        actionCamera_Controls->setText(QCoreApplication::translate("MainWindow", "Camera Controls", nullptr));
        label->setText(QCoreApplication::translate("MainWindow", "Metallic", nullptr));
        label_2->setText(QCoreApplication::translate("MainWindow", "Roughness", nullptr));
        label_3->setText(QCoreApplication::translate("MainWindow", "Ambient Occlusion", nullptr));
        label_4->setText(QCoreApplication::translate("MainWindow", "R", nullptr));
        label_5->setText(QCoreApplication::translate("MainWindow", "G", nullptr));
        label_6->setText(QCoreApplication::translate("MainWindow", "B", nullptr));
        label_7->setText(QCoreApplication::translate("MainWindow", "Albedo", nullptr));
        envMapButton->setText(QCoreApplication::translate("MainWindow", "Load Environment Map", nullptr));
        sceneButton->setText(QCoreApplication::translate("MainWindow", "Load Scene", nullptr));
        sphereButton->setText(QCoreApplication::translate("MainWindow", "Revert to Sphere", nullptr));
        label_8->setText(QCoreApplication::translate("MainWindow", "Displacement", nullptr));
        objButton->setText(QCoreApplication::translate("MainWindow", "Load OBJ", nullptr));
        menuFile->setTitle(QCoreApplication::translate("MainWindow", "File", nullptr));
        menuHelp->setTitle(QCoreApplication::translate("MainWindow", "Help", nullptr));
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H

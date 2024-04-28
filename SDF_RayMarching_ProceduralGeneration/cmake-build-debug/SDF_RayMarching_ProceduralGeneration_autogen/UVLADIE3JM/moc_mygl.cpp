/****************************************************************************
** Meta object code from reading C++ file 'mygl.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.2.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <memory>
#include "../../../src/mygl.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'mygl.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 68
#error "This file was generated using the moc from 6.2.2. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
struct qt_meta_stringdata_MyGL_t {
    const uint offsetsAndSize[28];
    char stringdata0[181];
};
#define QT_MOC_LITERAL(ofs, len) \
    uint(offsetof(qt_meta_stringdata_MyGL_t, stringdata0) + ofs), len 
static const qt_meta_stringdata_MyGL_t qt_meta_stringdata_MyGL = {
    {
QT_MOC_LITERAL(0, 4), // "MyGL"
QT_MOC_LITERAL(5, 11), // "slot_setRed"
QT_MOC_LITERAL(17, 0), // ""
QT_MOC_LITERAL(18, 13), // "slot_setGreen"
QT_MOC_LITERAL(32, 12), // "slot_setBlue"
QT_MOC_LITERAL(45, 16), // "slot_setMetallic"
QT_MOC_LITERAL(62, 17), // "slot_setRoughness"
QT_MOC_LITERAL(80, 10), // "slot_setAO"
QT_MOC_LITERAL(91, 20), // "slot_setDisplacement"
QT_MOC_LITERAL(112, 15), // "slot_loadEnvMap"
QT_MOC_LITERAL(128, 14), // "slot_loadScene"
QT_MOC_LITERAL(143, 12), // "slot_loadOBJ"
QT_MOC_LITERAL(156, 19), // "slot_revertToSphere"
QT_MOC_LITERAL(176, 4) // "tick"

    },
    "MyGL\0slot_setRed\0\0slot_setGreen\0"
    "slot_setBlue\0slot_setMetallic\0"
    "slot_setRoughness\0slot_setAO\0"
    "slot_setDisplacement\0slot_loadEnvMap\0"
    "slot_loadScene\0slot_loadOBJ\0"
    "slot_revertToSphere\0tick"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_MyGL[] = {

 // content:
      10,       // revision
       0,       // classname
       0,    0, // classinfo
      12,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       0,       // signalCount

 // slots: name, argc, parameters, tag, flags, initial metatype offsets
       1,    1,   86,    2, 0x0a,    1 /* Public */,
       3,    1,   89,    2, 0x0a,    3 /* Public */,
       4,    1,   92,    2, 0x0a,    5 /* Public */,
       5,    1,   95,    2, 0x0a,    7 /* Public */,
       6,    1,   98,    2, 0x0a,    9 /* Public */,
       7,    1,  101,    2, 0x0a,   11 /* Public */,
       8,    1,  104,    2, 0x0a,   13 /* Public */,
       9,    0,  107,    2, 0x0a,   15 /* Public */,
      10,    0,  108,    2, 0x0a,   16 /* Public */,
      11,    0,  109,    2, 0x0a,   17 /* Public */,
      12,    0,  110,    2, 0x0a,   18 /* Public */,
      13,    0,  111,    2, 0x08,   19 /* Private */,

 // slots: parameters
    QMetaType::Void, QMetaType::Int,    2,
    QMetaType::Void, QMetaType::Int,    2,
    QMetaType::Void, QMetaType::Int,    2,
    QMetaType::Void, QMetaType::Int,    2,
    QMetaType::Void, QMetaType::Int,    2,
    QMetaType::Void, QMetaType::Int,    2,
    QMetaType::Void, QMetaType::Double,    2,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,

       0        // eod
};

void MyGL::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<MyGL *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->slot_setRed((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 1: _t->slot_setGreen((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 2: _t->slot_setBlue((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 3: _t->slot_setMetallic((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 4: _t->slot_setRoughness((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 5: _t->slot_setAO((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 6: _t->slot_setDisplacement((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 7: _t->slot_loadEnvMap(); break;
        case 8: _t->slot_loadScene(); break;
        case 9: _t->slot_loadOBJ(); break;
        case 10: _t->slot_revertToSphere(); break;
        case 11: _t->tick(); break;
        default: ;
        }
    }
}

const QMetaObject MyGL::staticMetaObject = { {
    QMetaObject::SuperData::link<OpenGLContext::staticMetaObject>(),
    qt_meta_stringdata_MyGL.offsetsAndSize,
    qt_meta_data_MyGL,
    qt_static_metacall,
    nullptr,
qt_incomplete_metaTypeArray<qt_meta_stringdata_MyGL_t
, QtPrivate::TypeAndForceComplete<MyGL, std::true_type>
, QtPrivate::TypeAndForceComplete<void, std::false_type>, QtPrivate::TypeAndForceComplete<int, std::false_type>, QtPrivate::TypeAndForceComplete<void, std::false_type>, QtPrivate::TypeAndForceComplete<int, std::false_type>, QtPrivate::TypeAndForceComplete<void, std::false_type>, QtPrivate::TypeAndForceComplete<int, std::false_type>, QtPrivate::TypeAndForceComplete<void, std::false_type>, QtPrivate::TypeAndForceComplete<int, std::false_type>, QtPrivate::TypeAndForceComplete<void, std::false_type>, QtPrivate::TypeAndForceComplete<int, std::false_type>, QtPrivate::TypeAndForceComplete<void, std::false_type>, QtPrivate::TypeAndForceComplete<int, std::false_type>, QtPrivate::TypeAndForceComplete<void, std::false_type>, QtPrivate::TypeAndForceComplete<double, std::false_type>, QtPrivate::TypeAndForceComplete<void, std::false_type>, QtPrivate::TypeAndForceComplete<void, std::false_type>, QtPrivate::TypeAndForceComplete<void, std::false_type>, QtPrivate::TypeAndForceComplete<void, std::false_type>, QtPrivate::TypeAndForceComplete<void, std::false_type>


>,
    nullptr
} };


const QMetaObject *MyGL::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *MyGL::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_MyGL.stringdata0))
        return static_cast<void*>(this);
    return OpenGLContext::qt_metacast(_clname);
}

int MyGL::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = OpenGLContext::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 12)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 12;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 12)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 12;
    }
    return _id;
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE

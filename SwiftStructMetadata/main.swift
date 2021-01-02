//
//  main.swift
//  SwiftStructMetadata
//
//  Created by ZP on 2020/12/30.
//

import Foundation

struct StructMetadata {
    var kind: Int
    var desc: UnsafeMutablePointer<StructMetadataDesc>
}

struct StructMetadataDesc {
    var flags: Int32
    var parent: Int32
    var name: RelativeDirectPointer<CChar> //存放type的名称
    var accessFunctionPtr: RelativeDirectPointer<UnsafeRawPointer>
    var fields: RelativeDirectPointer<FieldDescriptor>
    var numFields: UInt32
    var fieldOffsetVectorOffset: UInt32
}

struct FieldDescriptor {
    var MangledTypeName: RelativeDirectPointer<CChar>
    var Superclass: RelativeDirectPointer<CChar>
    var kind: UInt16
    var FieldRecordSize: UInt16
    var NumFields: UInt32
    var fields: FieldRecord //连续的存储空间，记录属性字段
}

struct FieldRecord {
    var Flags: Int32
    var MangledTypeName: RelativeDirectPointer<CChar>
    var FieldName: RelativeDirectPointer<CChar>
}


struct RelativeDirectPointer<T> {
    var offset: Int32
    //由于要操作self 加上 mutating
    mutating func get() -> UnsafeMutablePointer<T> {
        let offset = self.offset
        //模拟this + offset
        //获取self指针
        return withUnsafePointer(to: &self) { p in
            //为了指针相加，先转成raw pointer再offset绑定到T.self再转回UnsafeMutablePointer
            return UnsafeMutablePointer(mutating: UnsafeRawPointer(p).advanced(by: numericCast(offset)).assumingMemoryBound(to: T.self))
        }
    }
}


struct Hotpot {
    var age = 18
    var name = "hotpot"
}

var h = Hotpot()
var p = Hotpot.self

//unsafeBitCast 按位强转 Hotpot.self 到 StructMetadata。8字节按位存储。不安全。
let ptr = unsafeBitCast(Hotpot.self as Any.Type, to: UnsafeMutablePointer<StructMetadata>.self)

//获取name。
/**
 1.ptr.pointer获取StructMetadata指针。
 2.desc.pointee获取desc指针。
 3.name获取type名称指针。
 4.最终通过get方法找到偏移地址存放的地址（也就是名称）。
 */
let namePtr = ptr.pointee.desc.pointee.name.get()
print(String(cString: namePtr))//Hotpot

//内存赋值
print(ptr.pointee.desc.pointee.numFields)

//获取FieldDescriptor
let fieldDescriptorPtr = ptr.pointee.desc.pointee.fields.get()
//获取recordPtr
let recordPtr = withUnsafePointer(to: &fieldDescriptorPtr.pointee.fields){
//先把fields转为UnsafeRawPointer，然后移动
    return UnsafeMutablePointer(mutating: UnsafeRawPointer($0).assumingMemoryBound(to:FieldRecord.self).advanced(by:0))
}
//获取`age`名称，通过advance控制
print(String(cString: recordPtr.pointee.FieldName.get()))


//var bufferPtr = UnsafeBufferPointer(start: UnsafeRawPointer(UnsafeRawPointer(ptr).assumingMemoryBound(to: Int.self).advanced(by: numericCast(ptr.pointee.desc.pointee.fieldOffsetVectorOffset))).assumingMemoryBound(to: Int32.self), count: Int(ptr.pointee.desc.pointee.numFields))


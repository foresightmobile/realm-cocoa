////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Realm

/// A protocol describing types that can parameterize a `RealmOptional`.
public protocol RealmOptionalType {
}

public extension RealmOptionalType {
    /// :nodoc:
    static func className() -> String {
        return ""
    }
}
extension Int: RealmOptionalType {}
extension Int8: RealmOptionalType {}
extension Int16: RealmOptionalType {}
extension Int32: RealmOptionalType {}
extension Int64: RealmOptionalType {}
extension Float: RealmOptionalType {}
extension Double: RealmOptionalType {}
extension Bool: RealmOptionalType {}

/*
public protocol RealmValue {
    static func getProperty(_ obj: Object, _ key: UInt16) -> Self
    static func setProperty(_ obj: Object, _ key: UInt16, _ value: Self)
}
extension Int: RealmValue {
    public static func getProperty(_ obj: Object, _ key: UInt16) -> Int {
        return RLMGetIntProperty(obj, key)
    }
    public static func setProperty(_ obj: Object, _ key: UInt16, _ value: Int) {
        RLMSetIntProperty(obj, key, value)
    }
}

@propertyWrapper
public struct RealmManagedProperty<Value: RealmValue> {
    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError("called wrappedValue getter") }
        set { fatalError("called wrappedValue setter") }
    }

    public init(defaultValue value: Value, primaryKey: Bool = false, indexed: Bool = false) {
        print("init: \(value) primaryKey: \(primaryKey)")
    }

    public static subscript<EnclosingSelf: Object, FinalValue>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, FinalValue>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
        ) -> Value {
        get {
            return Value.getProperty(object, object.propertyIndex(storageKeyPath))
        }
        set {
            Value.setProperty(object, object.propertyIndex(storageKeyPath), newValue)
        }
    }
}

class MyModel: Object {
    @RealmManagedProperty(defaultValue: nextPk(), primaryKey: true)
    var primaryKey: Int

    @RealmManagedProperty(defaultValue: nil)
    var value: String?
}
*/


/**
 A `RealmOptional` instance represents an optional value for types that can't be
 directly declared as `@objc` in Swift, such as `Int`, `Float`, `Double`, and `Bool`.

 To change the underlying value stored by a `RealmOptional` instance, mutate the instance's `value` property.
 */
@propertyWrapper
public final class RealmOptional<Value: RealmOptionalType>: RLMOptionalBase {
    /// The value the optional represents.
    public var wrappedValue: Value? {
        get {
            return RLMGetOptional(self).map(dynamicBridgeCast)
        }
        set {
            RLMSetOptional(self, newValue.map(dynamicBridgeCast))
        }
    }
    public var value: Value? {
        get {
            return self.wrappedValue
        }
        set {
            self.wrappedValue = newValue
        }
    }

    /**
     Creates a `RealmOptional` instance encapsulating the given default value.

     - parameter value: The value to store in the optional, or `nil` if not specified.
     */
    public init(_ value: Value?) {
        super.init()
        self.value = value
    }

    public init(initialValue value: Value? = nil) {
        super.init()
        self.value = value
    }
}

#if swift(>=4.1)
extension RealmOptional: Codable where Value: Codable {
    public convenience init(from decoder: Decoder) throws {
        self.init()
        // `try decoder.singleValueContainer().decode(Value?.self)` incorrectly
        // rejects null values: https://bugs.swift.org/browse/SR-7404
        let container = try decoder.singleValueContainer()
        self.value = container.decodeNil() ? nil : try container.decode(Value.self)
    }

    public func encode(to encoder: Encoder) throws {
        try self.value.encode(to: encoder)
    }
}
#endif

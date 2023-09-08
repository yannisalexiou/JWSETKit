//
//  File.swift
//  
//
//  Created by Amir Abbas Mousavian on 9/7/23.
//

import Foundation

/// JSON container for payloads and sections of JWS and JWE structures.
@dynamicMemberLookup
public protocol JSONWebContainer: Codable, Hashable {
    /// Storage of container values.
    var storage: JSONWebValueStorage { get set }
    
    /// Creates a container with empty storage.
    init()
}

extension JSONWebContainer {
    public init(from decoder: Decoder) throws {
        self = .init()
        let container = try decoder.singleValueContainer()
        self.storage = try container.decode(JSONWebValueStorage.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }
    
    /// Returns value of given key.
    public subscript<T>(_ member: String) -> T? {
        get {
            storage[member]
        }
        set {
            storage[member] = newValue
        }
    }
    
    /// Returns value of given key.
    public subscript<T>(dynamicMember member: String) -> T? {
        get {
            storage[member.jsonWebKey]
        }
        set {
            storage[member.jsonWebKey] = newValue
        }
    }
}

public struct ProtectedJSONWebContainer<Container: JSONWebContainer>: Codable, Hashable {
    public var protected: Data {
        didSet {
            if protected.isEmpty {
                value.storage = .init()
                return
            }
            do {
                value = try JSONDecoder().decode(Container.self, from: protected)
            } catch {
                protected = .init()
            }
        }
    }
    
    public var value: Container {
        didSet {
            if value.storage == .init() {
                protected = .init()
                return
            }
            do {
                protected = try JSONEncoder().encode(value)
            } catch {
                protected = .init()
            }
        }
    }
    
    public init(protected: Data) throws {
        self.protected = protected
        self.value = try JSONDecoder().decode(Container.self, from: protected)
    }
    
    public init(value: Container) throws {
        self.value = value
        self.protected = try JSONEncoder().encode(value).urlBase64EncodedData()
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        let encoded = try container.decode(String.self)
        guard let protected = Data(urlBase64Encoded: Data(encoded.utf8)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Protected is not a valid bas64url."))
        }
        self.protected = protected
        self.value = try JSONDecoder().decode(Container.self, from: protected)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let encoded = protected.urlBase64EncodedData()
        try container.encode(encoded)
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.protected == rhs.protected
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(protected)
    }
}

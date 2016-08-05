//
//  PokemonType+CoreDataProperties.swift
//  Pokegear GO
//
//  Created by Justin Oroz on 8/5/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

extension PokemonType {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PokemonType> {
        return NSFetchRequest<PokemonType>(entityName: "Type");
    }

    @NSManaged public var name: String?
    @NSManaged public var attacks: NSSet?
    @NSManaged public var pokemons: NSSet?
    @NSManaged public var strongAgainst: NSSet?
    @NSManaged public var weakAgainst: NSSet?

}

// MARK: Generated accessors for attacks
extension PokemonType {

    @objc(addAttacksObject:)
    @NSManaged public func addToAttacks(_ value: PokemonAttack)

    @objc(removeAttacksObject:)
    @NSManaged public func removeFromAttacks(_ value: PokemonAttack)

    @objc(addAttacks:)
    @NSManaged public func addToAttacks(_ values: NSSet)

    @objc(removeAttacks:)
    @NSManaged public func removeFromAttacks(_ values: NSSet)

}

// MARK: Generated accessors for pokemons
extension PokemonType {

    @objc(addPokemonsObject:)
    @NSManaged public func addToPokemons(_ value: Pokemon)

    @objc(removePokemonsObject:)
    @NSManaged public func removeFromPokemons(_ value: Pokemon)

    @objc(addPokemons:)
    @NSManaged public func addToPokemons(_ values: NSSet)

    @objc(removePokemons:)
    @NSManaged public func removeFromPokemons(_ values: NSSet)

}

// MARK: Generated accessors for strongAgainst
extension PokemonType {

    @objc(addStrongAgainstObject:)
    @NSManaged public func addToStrongAgainst(_ value: PokemonType)

    @objc(removeStrongAgainstObject:)
    @NSManaged public func removeFromStrongAgainst(_ value: PokemonType)

    @objc(addStrongAgainst:)
    @NSManaged public func addToStrongAgainst(_ values: NSSet)

    @objc(removeStrongAgainst:)
    @NSManaged public func removeFromStrongAgainst(_ values: NSSet)

}

// MARK: Generated accessors for weakAgainst
extension PokemonType {

    @objc(addWeakAgainstObject:)
    @NSManaged public func addToWeakAgainst(_ value: PokemonType)

    @objc(removeWeakAgainstObject:)
    @NSManaged public func removeFromWeakAgainst(_ value: PokemonType)

    @objc(addWeakAgainst:)
    @NSManaged public func addToWeakAgainst(_ values: NSSet)

    @objc(removeWeakAgainst:)
    @NSManaged public func removeFromWeakAgainst(_ values: NSSet)

}

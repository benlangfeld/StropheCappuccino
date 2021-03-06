/*
 * TNStropheGroup.j
 *
 * Copyright (C) 2010  Antoine Mercadal <antoine.mercadal@inframonde.eu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3.0 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

@import <Foundation/Foundation.j>
@import "TNStropheGlobals.j"


/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Group.
*/
@implementation TNStropheGroup : CPObject
{
    CPArray     _contacts   @accessors(getter=contacts);
    CPString    _name       @accessors(property=name);
}

+ (TNStropheGroup)stropheGroupWithName:(CPString)aName
{
    return [[TNStropheGroup alloc] initWithName:aName];
}

- (TNStropheGroup)initWithName:(CPString)aName
{
    if (self = [super init])
    {
        _contacts   = [CPArray array];
        _name       = aName;
    }

    return self;
}

- (CPString)description
{
    return _name;
}

- (void)changeName:(CPString)aName
{
    var oldName = _name;

    _name = aName;

    for (var i = 0; i < [self count]; i++)
    {
        var contact = [_contacts objectAtIndex:i];
        [contact removeGroupName:oldName];
        [contact addGroupName:_name];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheGroupRenamedNotification object:self];
}

- (void)addContact:(TNStropheContact)aContact
{
    if ([aContact class] != TNStropheContact)
        [CPException raise:"Invalid Object" reason:"You can only add TNStropheContacts"];

    [_contacts addObject:aContact];
}

- (void)removeContact:(TNStropheContact)aContact
{
    [_contacts removeObject:aContact];
}

- (int)count
{
    return [_contacts count];
}

@end

@implementation TNStropheGroup (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _contacts   = [aCoder decodeObjectForKey:@"_contacts"];
        _name       = [aCoder decodeObjectForKey:@"_name"];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_contacts forKey:@"_contacts"];
    [aCoder encodeObject:_name forKey:@"_name"];
}

@end

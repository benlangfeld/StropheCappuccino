/*
 * TNStropheClient.j
 *
 * Copyright (C) 2010  Ben Langfeld <ben@langfeld.me>
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

@import "TNStropheConnection.j"
@import "TNStropheJID.j"
@import "TNStropheStanza.j"
@import "Resources/Strophe/sha1.js"
@import "TNStropheGlobals.j"
@import "TNStropheRoster.j"


@implementation TNStropheClient : CPObject
{
    CPArray             _features               @accessors(readonly);
    CPString            _clientNode             @accessors(property=clientNode);
    CPString            _identityCategory       @accessors(property=identityCategory);
    CPString            _identityName           @accessors(property=identityName);
    CPString            _identityType           @accessors(property=identityType);
    CPString            _password               @accessors(property=password);
    id                  _delegate               @accessors(property=delegate);
    TNStropheConnection _connection             @accessors(property=connection);
    TNStropheJID        _JID                    @accessors(property=JID);
    TNStropheRoster     _roster                 @accessors(getter=roster);

    CPString            _userPresenceShow;
    CPString            _userPresenceStatus;
}

#pragma mark -
#pragma mark Class methods

+ (void)addNamespaceWithName:(CPString)aName value:(CPString)aValue
{
    Strophe.addNamespace(aName, aValue);
}

/*! instantiate a TNStropheClient object

    @param aService a url of a bosh service (MUST be complete url with http://)

    @return a valid TNStropheClient
*/
+ (TNStropheClient)clientWithService:(CPString)aService
{
    return [[TNStropheClient alloc] initWithService:aService];
}

/*! instantiate a TNStropheClient object

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aRosterClass the specific roster class to use (optional, defaults to TNStropheRoster)

    @return a valid TNStropheClient
*/
+ (TNStropheClient)clientWithService:(CPString)aService rosterClass:(id)aRosterClass
{
    return [[TNStropheClient alloc] initWithService:aService rosterClass:aRosterClass];
}

/*! instantiate a TNStropheClient object

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aJID a JID to connect to the XMPP server
    @param aPassword the password associated to the JID

    @return a valid TNStropheClient
*/
+ (TNStropheClient)clientWithService:(CPString)aService JID:(TNStropheJID)aJID password:(CPString)aPassword
{
    return [[TNStropheClient alloc] initWithService:aService JID:aJID password:aPassword];
}

/*! instantiate a TNStropheClient object

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aJID a JID to connect to the XMPP server
    @param aPassword the password associated to the JID
    @param aRosterClass the specific roster class to use (optional, defaults to TNStropheRoster)

    @return a valid TNStropheClient
*/
+ (TNStropheClient)clientWithService:(CPString)aService JID:(TNStropheJID)aJID password:(CPString)aPassword rosterClass:(id)aRosterClass
{
    return [[TNStropheClient alloc] initWithService:aService JID:aJID password:aPassword rosterClass:aRosterClass];
}


#pragma mark -
#pragma mark Initialization

/*! initialize the TNStropheClient

    @param aService a url of a bosh service (MUST be complete url with http://)
*/
- (id)initWithService:(CPString)aService
{
    return [self initWithService:aService rosterClass:nil];
}

/*! initialize the TNStropheClient

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aRosterClass the specific roster class to use (optional, defaults to TNStropheRoster)
*/
- (id)initWithService:(CPString)aService rosterClass:(id)aRosterClass
{
    if (self = [super init])
    {
        _connection                 = [TNStropheConnection connectionWithService:aService andDelegate:self];
        if (!aRosterClass)
            aRosterClass = TNStropheRoster;
        _roster                     = [aRosterClass rosterWithConnection:_connection];
        _userPresenceShow           = TNStropheContactStatusOffline;
        _userPresenceStatus         = @"";
        _clientNode                 = @"http://cappuccino.org";
        _identityCategory           = @"client";
        _identityName               = @"StropheCappuccino";
        _identityType               = @"web";
        _features                   = [Strophe.NS.CAPS, Strophe.NS.DISCO_INFO, Strophe.NS.DISCO_ITEMS];
    }

    return self;
}

/*! initialize the TNStropheClient

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aJID a JID to connect to the XMPP server
    @param aPassword the password associated to the JID
*/
- (id)initWithService:(CPString)aService JID:(TNStropheJID)aJID password:(CPString)aPassword
{
    return [self initWithService:aService JID:aJID password:aPassword rosterClass:nil];
}

/*! initialize the TNStropheClient

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aJID a JID to connect to the XMPP server
    @param aPassword the password associated to the JID
    @param aRosterClass the specific roster class to use (optional, defaults to TNStropheRoster)
*/
- (id)initWithService:(CPString)aService JID:(TNStropheJID)aJID password:(CPString)aPassword rosterClass:(id)aRosterClass
{
    if (self = [self initWithService:aService rosterClass:aRosterClass])
    {
        _JID        = aJID;
        _password   = aPassword;
    }

    return self;
}


#pragma mark -
#pragma mark Connection

- (void)connect
{
    var pingDict = [CPDictionary dictionaryWithObjectsAndKeys:@"iq", @"name", @"get", @"type"];
    [_connection registerSelector:@selector(_didReceivePing:) ofObject:self withDict:pingDict];
    [_connection connectWithJID:_JID andPassword:_password];
}

- (void)disconnect
{
    [_connection disconnect];
}

- (void)onStropheConnecting:(id)aConnection
{
    if ([_delegate respondsToSelector:@selector(onStropheConnecting:)])
        [_delegate onStropheConnecting:self];
}

- (void)onStropheConnected:(TNStropheConnection)aConnection
{
    /*! Upon authenticating with a server and binding a resource (thus becoming a connected resource as
        defined in [XMPP‑CORE]), a client SHOULD request the roster before sending initial presence
    */
    [_roster getRoster];

    [self _sendInitialPresence];

    [self _sendCAPS];

    if ([_delegate respondsToSelector:@selector(onStropheConnected:)])
        [_delegate onStropheConnected:self];
}

- (void)onStropheConnectFail:(id)aConnection
{
    [_roster clear];
    if ([_delegate respondsToSelector:@selector(onStropheConnectFail:)])
        [_delegate onStropheConnectFail:self];
}

- (void)onStropheDisconnecting:(id)aConnection
{
    if ([_delegate respondsToSelector:@selector(onStropheDisconnecting:)])
        [_delegate onStropheDisconnecting:self];
}

- (void)onStropheDisconnected:(TNStropheConnection)aConnection
{
    _userPresenceShow   = TNStropheContactStatusOffline;
    _userPresenceStatus = @"";
    [_roster clear];
    if ([_delegate respondsToSelector:@selector(onStropheDisconnected:)])
        [_delegate onStropheDisconnected:self];
}

- (void)onStropheAuthenticating:(id)aConnection
{
    if ([_delegate respondsToSelector:@selector(onStropheAuthenticating:)])
        [_delegate onStropheAuthenticating:self];
}

- (void)onStropheAuthFail:(id)aConnection
{
    if ([_delegate respondsToSelector:@selector(onStropheAuthFail:)])
        [_delegate onStropheAuthFail:self];
}

- (void)onStropheError:(id)aConnection
{
    [_roster clear];
    if ([_delegate respondsToSelector:@selector(onStropheError:)])
        [_delegate onStropheError:self];
}

- (void)connection:(id)aConnection errorCondition:(CPString)anErrorCondition
{
    if ([_delegate respondsToSelector:@selector(client:errorCondition:)])
        [_delegate client:self errorCondition:anErrorCondition];
}


#pragma mark -
#pragma mark Features

- (void)_sendInitialPresence
{
    var presenceHandleParams = [CPDictionary dictionaryWithObjectsAndKeys:@"presence", @"name", [_JID bare], @"from", {@"matchBare": true}, @"options"];
    [_connection registerSelector:@selector(_didPresenceUpdate:) ofObject:self withDict:presenceHandleParams];
    [self setPresenceShow:TNStropheContactStatusOnline status:@""];
}

- (BOOL)_didReceivePing:(TNStropheStanza)aStanza
{
    if ([aStanza containsChildrenWithName:@"ping"] && [[aStanza firstChildWithName:@"ping"] namespace] == Strophe.NS.PING)
    {
        CPLog.debug("Ping received. Sending pong.");
        [_connection send:[TNStropheStanza iqWithAttributes:{'to': [[aStanza from] bare], 'id': [aStanza ID], 'type': 'result'}]];
    }
    return YES;
}

- (void)addFeature:(CPString)aFeatureNamespace
{
    [_features addObject:aFeatureNamespace];
}

- (void)removeFeature:(CPString)aFeatureNamespace
{
    [_features removeObjectIdenticalTo:aFeatureNamespace];
}

- (CPString)_clientVer
{
    return SHA1.b64_sha1(_features.join());
}

- (void)_sendCAPS
{
    var caps = [TNStropheStanza presence];
    [caps addChildWithName:@"c" andAttributes:{ "xmlns":Strophe.NS.CAPS, "node":_clientNode, "hash":"sha-1", "ver":[self _clientVer] }];

    [_connection registerSelector:@selector(handleFeaturesDisco:)
                  ofObject:self
                  withDict:[CPDictionary dictionaryWithObjectsAndKeys:@"iq", @"name", @"get", @"type", Strophe.NS.DISCO_INFO, "namespace"]];

    [_connection send:caps];
}

- (BOOL)handleFeaturesDisco:(TNStropheStanza)aStanza
{
    var resp = [TNStropheStanza iqWithAttributes:{"id":[_connection getUniqueId], "type":"result"}];

    [resp setTo:[aStanza from]];

    [resp addChildWithName:@"query" andAttributes:{"xmlns":Strophe.NS.DISCO_INFO, "node":(_clientNode + '#' + [self _clientVer])}];
    [resp addChildWithName:@"identity" andAttributes:{"category":_identityCategory, "name":_identityName, "type":_identityType}];
    [resp up];

    for (var i = 0; i < [_features count]; i++)
    {
        [resp addChildWithName:@"feature" andAttributes:{"var":[_features objectAtIndex:i]}];
        [resp up];
    }

    [_connection send:resp];

    return YES;
}

/*! publish a PEP payload
    @param aPayload: the payload to send
    @param aNode: the node to publish to
*/
- (void)publishPEPPayload:(TNXMLNode)aPayload toNode:(CPString)aNode
{
    var uid     = [_connection getUniqueId],
        stanza  = [TNStropheStanza iqWithAttributes:{"type":"set", "id":uid}],
        params  = [CPDictionary dictionaryWithObject:uid forKey:@"id"];

    [stanza addChildWithName:@"pubsub" andAttributes:{"xmlns":Strophe.NS.PUBSUB}]
    [stanza addChildWithName:@"publish" andAttributes:{"node":aNode}];
    [stanza addChildWithName:@"item"];
    [stanza addNode:aPayload];

    [_connection registerSelector:@selector(_didPublishPEP:) ofObject:self withDict:params];
    [_connection send:stanza];
}

- (void)_didPublishPEP:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        CPLog.debug("Publish succeeded!");
    else
        CPLog.error("Cannot publish the pubsub item in node with name: " + _nodeName);

    return NO;
}


#pragma mark -
#pragma mark Presence

- (void)setPresenceShow:(CPString)aPresenceShow status:(CPString)aStatus
{
    if (aPresenceShow === _userPresenceShow && aStatus === _userPresenceStatus)
        return;

    var presence = [TNStropheStanza presence];

    _userPresenceShow   = aPresenceShow || _userPresenceShow;
    _userPresenceStatus = aStatus || _userPresenceStatus;

    [presence addChildWithName:@"status"];
    [presence addTextNode:_userPresenceStatus];
    [presence up];
    [presence addChildWithName:@"show"];
    [presence addTextNode:_userPresenceShow];

    [_connection send:presence];
}

- (BOOL)_didPresenceUpdate:(TNStropheStanza)aStanza
{
    var shouldNotify = NO;

    if ([aStanza firstChildWithName:@"show"])
    {
        _userPresenceShow = [[aStanza firstChildWithName:@"show"] text];
        shouldNotify = YES;
    }

    if ([aStanza firstChildWithName:@"status"])
    {
        _userPresenceStatus = [[aStanza firstChildWithName:@"status"] text];
        shouldNotify = YES;
    }

    if (shouldNotify)
    {
        var presenceInformation = [CPDictionary dictionaryWithObjectsAndKeys:_userPresenceShow, @"show", _userPresenceStatus, @"status"];
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheClientPresenceUpdatedNotification object:self userInfo:presenceInformation];
    }

    return YES;
}


#pragma mark -
#pragma mark vCard

/*! get the vCard of the client JID
*/
- (void)getVCard
{
    var uid         = [_connection getUniqueId],
        vcardStanza = [TNStropheStanza iqWithAttributes:{@"type": @"get", @"id": uid}],
        params      = [CPDictionary dictionaryWithObjectsAndKeys: uid, @"id"];

    [vcardStanza addChildWithName:@"vCard" andAttributes:{@"xmlns": @"vcard-temp"}];

    [_connection registerSelector:@selector(_didReceiveCurrentUserVCard:) ofObject:self withDict:params];
    [_connection send:vcardStanza];
}

/*! compute the answer of the vCard stanza
    @param aStanza the stanza containing the vCard
*/
- (void)_didReceiveCurrentUserVCard:(TNStropheStanza)aStanza
{
    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheClientVCardReceived object:self userInfo:aStanza];
}

/*! set the vCard of the connection JID and send the given message of of the given object with the given user info
    @param aVCard TNXMLNode containing the vCard
    @param anObject the target object
    @param aSelector the selector to send to the target object
    @param someUserInfo random informations
*/
- (void)setVCard:(TNXMLNode)aVCard object:(CPObject)anObject selector:(SEL)aSelector userInfo:(id)someUserInfo
{
    var uid     = [_connection getUniqueId],
        stanza  = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"set"}],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza addNode:aVCard];

    [_connection registerSelector:@selector(notifyVCardUpdate:) ofObject:self withDict:params];
    [_connection registerSelector:aSelector ofObject:anObject withDict:params userInfo:someUserInfo];
    [_connection send:stanza];
}

/*! notify XMPP user for changes in vCard
*/
- (void)notifyVCardUpdate:(TNStropheStanza)aStanza
{
    var uid     = [_connection getUniqueId],
        stanza  = [TNStropheStanza presenceWithAttributes:{@"id": uid}],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza addChildWithName:@"status"];
    [stanza addTextNode:_userPresenceStatus];
    [stanza up]
    [stanza addChildWithName:@"show"];
    [stanza addTextNode:_userPresenceShow];
    [stanza up]
    [stanza addChildWithName:@"x" andAttributes:{"xmlns": "vcard-temp:x:update"}];

    // debug
    //[_connection registerSelector:@selector(_didNotifyVCardUpdate:) ofObject:self withDict:params];

    [_connection send:stanza];
}

/*! called when notification of vCard changes have been sent
*/
- (void)_didNotifyVCardUpdate:(TNStropheStanza)aStanza
{
    CPLog.trace([aStanza stringValue]);
}

@end

@implementation TNStropheClient (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _JID                        = [aCoder decodeObjectForKey:@"_JID"];
        _password                   = [aCoder decodeObjectForKey:@"_password"];
        _delegate                   = [aCoder decodeObjectForKey:@"_delegate"];
        _connection                 = [aCoder decodeObjectForKey:@"_connection"];
        _roster                     = [aCoder decodeObjectForKey:@"_roster"];
        _registeredHandlers         = [aCoder decodeObjectForKey:@"_registeredHandlers"];
        _registeredTimedHandlers    = [aCoder decodeObjectForKey:@"_registeredTimedHandlers"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_JID forKey:@"_JID"];
    [aCoder encodeObject:_password forKey:@"_password"];
    [aCoder encodeObject:_connection forKey:@"_connection"];
    [aCoder encodeObject:_roster forKey:@"_roster"];
    [aCoder encodeObject:_registeredHandlers forKey:@"_registeredHandlers"];
    [aCoder encodeObject:_registeredTimedHandlers forKey:@"_registeredTimedHandlers"];
}

@end

import 'Util.dart';

class ItemData extends Object {
  String?   itemId;
  String?   itemClass;
  String?   catalogVersion;
  String?   displayName;
  String?   description;
  dynamic?  virtualCurrencyPrices;
  dynamic?  realCurrencyPrices;
  dynamic?  tags;
  dynamic?  consumable;
  bool?     canBecomeCharacter;
  dynamic?  container;
  bool?     isStackable;
  bool?     isTradable;
  bool?     isLimitedEdition;
  bool      isSelected = false;
  int?      initialLimitedEditionCount;
  String    issueCount = "1";

  ItemData({
    this.itemId,
    this.itemClass,
    this.catalogVersion,
    this.displayName,
    this.description,
    this.virtualCurrencyPrices,
    this.realCurrencyPrices,
    this.tags,
    this.consumable,
    this.canBecomeCharacter,
    this.container,
    this.isStackable,
    this.isTradable,
    this.isLimitedEdition,
    this.initialLimitedEditionCount,
  });

  @override
  String toString() {
    return indentEncoder.convert({
        "itemId":                       itemId,
        "itemClass":                    itemClass,
        "catalogVersion":               catalogVersion,
        "displayName":                  displayName,
        "description":                  description,
        "virtualCurrencyPrices":        virtualCurrencyPrices,
        "realCurrencyPrices":           realCurrencyPrices,
        "tags":                         tags,
        "consumable":                   consumable,
        "canBecomeCharacter":           canBecomeCharacter,
        "container":                    container,
        "isStackable":                  isStackable,
        "isTradable":                   isTradable,
        "isLimitedEdition":             isLimitedEdition,
        "isSelected":                   isSelected,
        "initialLimitedEditionCount":   initialLimitedEditionCount,
        "issueCount":                   issueCount,
    });
  }
}



class Metadata extends Object {
    String?  characterID;
    String?  server;
    String?  nickName;
    String?  costume;
    String?  weapon;
    String?  raideName;
    String?  petName;
    String?  returnUserEvent;
    int?     createAt;
    int?     lastTimeLogin;
    int?     itemTutorial;

    Metadata({
        this.characterID,
        this.server,
        this.nickName,
        this.costume,
        this.weapon,
        this.raideName,
        this.petName,
        this.returnUserEvent,
        this.createAt,
        this.lastTimeLogin,
        this.itemTutorial
    });

    Metadata.withMap(Map data)
    {
        characterID     = data["CharacterID"];
        server          = data["Server"];
        nickName        = data["NickName"];
        costume         = data["Costume"];
        weapon          = data["Weapon"];
        raideName       = data["RaideName"];
        petName         = data["PetName"];
        returnUserEvent = data["ReturnUserEvent"];
        createAt        = data["CreateAt"];
        lastTimeLogin   = data["LastTimeLogin"];
        itemTutorial    = data["ItemTutorial"];
    }
}
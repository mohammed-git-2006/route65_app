
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:route65/l10n/l10n.dart';

import 'l10n/animation_set.dart';

class MealView extends StatefulWidget {
  const MealView({super.key});

  @override
  State<MealView> createState() => _MealViewState();
}

enum FriesTypes {
  WEDGES, NORMAL, CURLY, NONE
}

enum PattyType {
  SMASHED, NORMAL, SPECIAL
}

enum BreadType {
  NORMAL, POTATO, FIT
}

class _MealViewState extends State<MealView> with TickerProviderStateMixin {
  List<AnimationSet> animations = [];
  final isMealAnimation = AnimationSet(), isSandwichAnimation = AnimationSet();
  final isNormalFries = AnimationSet(), isWedges = AnimationSet();
  final isCurly = AnimationSet(), friesOptionsAnimation = AnimationSet(), r1Animation = AnimationSet(), r2Animation = AnimationSet();
  final is65Bun = AnimationSet(), isPotatoBun = AnimationSet(), isFitBun = AnimationSet(), r3Animation = AnimationSet();
  FriesTypes friesType = FriesTypes.NORMAL;
  PattyType pattyType = PattyType.NORMAL;
  BreadType breadType = BreadType.NORMAL;
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isMealAnimation.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    isSandwichAnimation.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    isNormalFries.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    isCurly.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    isWedges.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    is65Bun.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    isPotatoBun.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    isFitBun.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    isWedges.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    friesOptionsAnimation.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    r1Animation.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    r2Animation.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    r3Animation.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
    r1Animation.whenHalf(r2Animation);
    r2Animation.whenHalf(r3Animation);
    isMealAnimation.start();
    isNormalFries.start();
    is65Bun.start();
    friesOptionsAnimation.start();
  }

  bool isMeal = true;
  int grams = 0, orderQ = 1;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;
    final dic = L10n.of(context)!;
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final menuItem = args['data'];
    final cat = args['category'];
    final components = args['cs'];
    final itemName = menuItem[isAr ? 'na' : 'ne'];
    final incrementalUnit = cat == 'Chicken' ? 130 : (cat == 'Beef' ? (pattyType == PattyType.NORMAL ? 50 : 100) : 0);
    final minGrams = (cat == 'Chicken' ? 130 : (menuItem['id'] as int == 9 ? 150 : 100));
    grams = grams == 0 ? minGrams : grams;
    double price = menuItem['p'] + (breadType == BreadType.POTATO ? .5 : .0);
    if (!isMeal) price -= 1.0;
    switch(friesType) {
      case FriesTypes.NORMAL:
        break;
      case FriesTypes.WEDGES:
        price += .4;
        break;
      case FriesTypes.CURLY:
        price += .5;
        break;
      case FriesTypes.NONE:
        break;
    }

    if (cat == 'Chicken') {
      final extraPatties = (grams - minGrams) / 130;
      if (pattyType == PattyType.SPECIAL) {
        price += .5;
        price += (extraPatties * 3.0);
      } else {
        price += extraPatties * 2.5;
      }
    } else {
      price += ((grams  - minGrams) / 50.0);
    }

    final isAppetizer = cat == 'Appetizers';


    final optionsDecoration = BoxDecoration(
      color: HSLColor.fromColor(cs.surface).withLightness(.9725).toColor(),
      border: Border.all(color: Colors.grey.shade300, width: 2),
      borderRadius: BorderRadius.circular(15)
    );

    if (animations.isEmpty && cat != 'Appetizers') {
      for(int i=0;i<menuItem['c'].length;++i) {
        final _animation = new AnimationSet()..init(this, .0, 1.0, Durations.medium1, Curves.easeInBack);
        if (i == menuItem['c'].length-1) _animation.whenDone(r1Animation);
        animations.add(_animation);
        Future.delayed(Duration(milliseconds: 200 * i)).then((_) => animations[i].start());
      }
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 30,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [BoxShadow(
                        color: cs.secondary.withAlpha(50),
                        spreadRadius: 10,
                        blurRadius: 10,
                        offset: Offset(0, -10)
                      )]
                    ),
                    height: 350,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Hero(
                            tag: menuItem['na'],
                            child: Container(
                              width: size.width,
                              height: 350,
                              decoration: BoxDecoration(
                                image: DecorationImage(image: args['image_provider'] as ImageProvider,
                                  fit: BoxFit.cover)
                              ),
                            ),
                          ),
                        ),

                        Positioned(top: 10 + MediaQuery.of(context).padding.top, right: 10, child: GestureDetector(
                          onTap: () => Navigator.of(context).pop({'ordered' : false}),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(45)
                            ),
                            padding: EdgeInsets.all(5),
                            child: Transform.rotate(angle: math.pi / 4, child: Icon(Icons.add, color: cs.primary, size: 25,)),
                          ),
                        ),)
                      ],
                    ),
                  ),

                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(itemName, style: TextStyle(fontSize: size.width * .065, fontWeight: FontWeight.bold),)),
                      Text('${(price * orderQ).toStringAsFixed(2)} JD', style: TextStyle(color: cs.secondary, fontSize: size.width * .065, fontWeight: FontWeight.bold),
                        textDirection: isAr ? TextDirection.ltr : TextDirection.rtl,),
                    ],
                  ),),

                  if (!isAppetizer) Padding(padding: EdgeInsets.symmetric(horizontal: 10.0), child: Wrap(
                    runSpacing: 10,
                    spacing: 15,
                    children: List.generate(menuItem['c'].length, (i) {
                      return Transform.translate(
                        offset: Offset(.0, math.sin(math.pi * animations[i].value) * -10),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                          decoration: BoxDecoration(
                            color: cs.secondary.withAlpha(35),
                            borderRadius: BorderRadius.circular(25)
                          ),
                          child: Row(spacing: 5, mainAxisSize: MainAxisSize.min, children: [
                            Text('${components[menuItem['c'][i]][2]}'), Text('${components[menuItem['c'][i]][isAr ? 1 : 0]}', style: TextStyle(fontWeight: FontWeight.bold,
                                  color: cs.secondary),)
                          ],),
                        ),
                      );
                    }),
                  ),),

                  if (!isAppetizer) Transform.translate(
                    offset: Offset(.0, -10 * math.sin(math.pi * r1Animation.value)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Row(
                        spacing: 15,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                if (!isMeal) {
                                  isSandwichAnimation.controller.reverse();
                                } else {
                                  isMealAnimation.reset();
                                }

                                if (friesOptionsAnimation.value != 1.0) friesOptionsAnimation..reset()..start();
                                isMealAnimation.start();
                                isMeal = true;
                                if(friesType == FriesTypes.NONE) {
                                  friesType = FriesTypes.NORMAL;
                                }
                              }),
                              child: Container(
                                decoration: optionsDecoration,
                                padding: EdgeInsets.all(10),
                                child: Column(children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    spacing: 10,
                                    children: [
                                      Text(dic.meal, style: TextStyle(fontWeight: FontWeight.bold),),
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isMeal ? cs.secondary : Colors.transparent,
                                          border: optionsDecoration.border
                                        ),

                                        padding: EdgeInsets.all(5),

                                        child: Opacity(
                                          opacity: isMealAnimation.value,
                                          child: isMeal ? Icon(Icons.check, color: cs.surface, size: 15,) : SizedBox(width: 15, height: 15,)
                                        ),
                                      )
                                    ],
                                  ),
                                  Text('+ 0.0 JD'),
                                ],),
                              ),
                            ),
                          ),

                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                if (isMeal) {
                                  isMealAnimation.controller.reverse();
                                } else {
                                  isSandwichAnimation.reset();
                                }

                                friesOptionsAnimation.controller.reverse();
                                isSandwichAnimation.start();

                                [isNormalFries, isWedges, isMeal].map((a) => (a as AnimationSet).controller.reverse());
                                friesType = FriesTypes.NONE;

                                isMeal = false;
                              }),
                              child: Container(
                                decoration: optionsDecoration,
                                padding: EdgeInsets.all(10),
                                child: Column(children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    spacing: 10,
                                    children: [
                                      Text(dic.sandwich, style: TextStyle(fontWeight: FontWeight.bold),),
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: !isMeal ? cs.secondary : Colors.transparent,
                                          border: optionsDecoration.border
                                        ),

                                        padding: EdgeInsets.all(5),

                                        child: Opacity(
                                          opacity: isSandwichAnimation.value,
                                          child: !isMeal ? Icon(Icons.check, color: cs.surface, size: 15,) : SizedBox(width: 15, height: 15,)
                                        ),
                                      )
                                    ],
                                  ),
                                  Text('- 1.0 JD'),
                                ],),
                              ),
                            ),
                          )

                        ],
                      ),
                    ),
                  ),

                  if (!isAppetizer && cat != 'Hotdog') Transform.translate(
                    offset: Offset(.0, -10 * math.sin(math.pi * r2Animation.value)),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: 15,
                        children: [
                          SizedBox(width: 15,),

                          GestureDetector(
                            onTap: () => setState(() {
                              setState(() {
                                isPotatoBun.reverse();
                                isFitBun.reverse();
                                is65Bun.start();
                                breadType = BreadType.NORMAL;
                              });
                            }),
                            child: Container(
                              decoration: optionsDecoration,
                              padding: EdgeInsets.all(10),
                              child: Column(children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  spacing: 10,
                                  children: [
                                    Text(dic.b_65, style: TextStyle(fontWeight: FontWeight.bold),),
                                    Container(
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: breadType == BreadType.NORMAL ? cs.secondary : Colors.transparent,
                                          border: optionsDecoration.border
                                      ),

                                      padding: EdgeInsets.all(5),

                                      child: Opacity(
                                          opacity: is65Bun.value,
                                          child: breadType == BreadType.NORMAL ? Icon(Icons.check, color: cs.surface, size: 15,) : SizedBox(width: 15, height: 15,)
                                      ),
                                    )
                                  ],
                                ),
                                Text('+ 0.0 JD'),
                              ],),
                            ),
                          ),

                          GestureDetector(
                            onTap: () => setState(() {
                              setState(() {
                                is65Bun.reverse();
                                isFitBun.reverse();
                                isPotatoBun.start();
                                breadType = BreadType.POTATO;
                              });
                            }),
                            child: Container(
                              decoration: optionsDecoration,
                              padding: EdgeInsets.all(10),
                              child: Column(children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  spacing: 10,
                                  children: [
                                    Text(dic.b_potbun, style: TextStyle(fontWeight: FontWeight.bold),),
                                    Container(
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: breadType == BreadType.POTATO ? cs.secondary : Colors.transparent,
                                          border: optionsDecoration.border
                                      ),

                                      padding: EdgeInsets.all(5),

                                      child: Opacity(
                                          opacity: isPotatoBun.value,
                                          child: breadType == BreadType.POTATO ? Icon(Icons.check, color: cs.surface, size: 15,) : SizedBox(width: 15, height: 15,)
                                      ),
                                    )
                                  ],
                                ),
                                Text('+ 0.5 JD'),
                              ],),
                            ),
                          ),

                          GestureDetector(
                            onTap: () => setState(() {
                              setState(() {
                                is65Bun.reverse();
                                isFitBun.start();
                                isPotatoBun.reverse();
                                breadType = BreadType.FIT;
                              });
                            }),
                            child: Container(
                              decoration: optionsDecoration,
                              padding: EdgeInsets.all(10),
                              child: Column(children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  spacing: 10,
                                  children: [
                                    Text(dic.b_fit, style: TextStyle(fontWeight: FontWeight.bold),),
                                    Container(
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: breadType == BreadType.FIT ? cs.secondary : Colors.transparent,
                                          border: optionsDecoration.border
                                      ),

                                      padding: EdgeInsets.all(5),

                                      child: Opacity(
                                          opacity: isFitBun.value,
                                          child: breadType == BreadType.FIT ? Icon(Icons.check, color: cs.surface, size: 15,) : SizedBox(width: 15, height: 15,)
                                      ),
                                    )
                                  ],
                                ),
                                Text('+ 0.0 JD'),
                              ],),
                            ),
                          ),

                          SizedBox(width: 15,)
                        ],
                      ),
                    ),
                  ),

                  if (!isAppetizer) Transform.translate(
                    offset: Offset(.0, -10 * math.sin(math.pi * r3Animation.value)),
                    child: Opacity(
                      opacity: ((friesOptionsAnimation.value * 2.0) - 1).clamp(.0, 1.0),
                      child: SizedBox(
                        height: 73 * (friesOptionsAnimation.value < .5 ? .0 : 1.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            spacing: 15,
                            children: [
                              SizedBox(width: 15,),

                              GestureDetector(
                                onTap: () => setState(() {

                                  if (friesType == FriesTypes.NORMAL) {
                                    isWedges.controller.reverse();
                                    isCurly.controller.reverse();
                                    isNormalFries.controller.reverse();
                                    friesType = FriesTypes.NONE;
                                  } else {
                                    isNormalFries.reset();
                                    isNormalFries.start();
                                    friesType = FriesTypes.NORMAL;
                                  }

                                }),
                                child: Container(
                                  decoration: optionsDecoration,
                                  padding: EdgeInsets.all(10),
                                  child: Column(spacing: 0, children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      spacing: 10,
                                      children: [
                                        Text(dic.pnormal, style: TextStyle(fontWeight: FontWeight.bold),),
                                        Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: friesType == FriesTypes.NORMAL ? cs.secondary : Colors.transparent,
                                              border: optionsDecoration.border
                                          ),

                                          padding: EdgeInsets.all(5),

                                          child: Opacity(
                                              opacity: isNormalFries.value,
                                              child: friesType == FriesTypes.NORMAL ? Icon(Icons.check, color: cs.surface, size: 15,) : SizedBox(width: 15, height: 15,)
                                          ),
                                        )
                                      ],
                                    ),
                                    Text('+ 0.0 JD'),
                                  ],),
                                ),
                              ),

                              GestureDetector(
                                onTap: () => setState(() {
                                  if (friesType == FriesTypes.CURLY) {
                                    isWedges.controller.reverse();
                                    isCurly.controller.reverse();
                                    isNormalFries.controller.reverse();
                                    friesType = FriesTypes.NONE;
                                  } else {
                                    isCurly.reset();
                                    isCurly.start();
                                    friesType = FriesTypes.CURLY;
                                  }
                                }),
                                child: Container(
                                  decoration: optionsDecoration,
                                  padding: EdgeInsets.all(10),
                                  child: Column(children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      spacing: 10,
                                      children: [
                                        Text(dic.pcurly, style: TextStyle(fontWeight: FontWeight.bold),),
                                        Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: friesType == FriesTypes.CURLY ? cs.secondary : Colors.transparent,
                                              border: optionsDecoration.border
                                          ),

                                          padding: EdgeInsets.all(5),

                                          child: Opacity(
                                              opacity: isCurly.value,
                                              child: friesType == FriesTypes.CURLY ? Icon(Icons.check, color: cs.surface, size: 15,) : SizedBox(width: 15, height: 15,)
                                          ),
                                        )
                                      ],
                                    ),
                                    Text('+ 0.5 JD'),
                                  ],),
                                ),
                              ),

                              GestureDetector(
                                onTap: () => setState(() {
                                  if (friesType == FriesTypes.WEDGES) {
                                    isWedges.controller.reverse();
                                    isCurly.controller.reverse();
                                    isNormalFries.controller.reverse();
                                    friesType = FriesTypes.NONE;
                                  } else {
                                    isWedges.reset();
                                    isWedges.start();
                                    friesType = FriesTypes.WEDGES;
                                  }
                                }),
                                child: Container(
                                  decoration: optionsDecoration,
                                  padding: EdgeInsets.all(10),
                                  child: Column(children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      spacing: 10,
                                      children: [
                                        Text(dic.pwidges, style: TextStyle(fontWeight: FontWeight.bold),),
                                        Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: friesType == FriesTypes.WEDGES ? cs.secondary : Colors.transparent,
                                              border: optionsDecoration.border
                                          ),

                                          padding: EdgeInsets.all(5),

                                          child: Opacity(
                                              opacity: isWedges.value,
                                              child: friesType == FriesTypes.WEDGES ? Icon(Icons.check, color: cs.surface, size: 15,) : SizedBox(width: 15, height: 15,)
                                          ),
                                        )
                                      ],
                                    ),
                                    Text('+ 0.4 JD'),
                                  ],),
                                ),
                              ),

                              SizedBox(width: 15,),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (!isAppetizer && cat != 'Hotdog') Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownMenu(dropdownMenuEntries: ([[dic.pa_normal, PattyType.NORMAL], cat == 'Chicken' ?
                        [dic.pa_special, PattyType.SPECIAL] : [dic.pa_smashed, PattyType.SMASHED]]).map((content) {
                        return DropdownMenuEntry(value: content[1], label: content[0] as String,
                          style: ElevatedButton.styleFrom(foregroundColor: cs.surface));
                      }).toList(), onSelected: (selectedType) {
                        setState(() {
                          pattyType = selectedType as PattyType;
                          if (pattyType == PattyType.SMASHED && (grams % 100) == 50) {
                            setState(() {
                              if (grams == minGrams) {
                                grams += 50;
                              } else {
                                grams -= 50;
                              }
                            });
                          }
                        });
                        // print(selectedType);
                      }, initialSelection: PattyType.NORMAL, inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: cs.secondary.withAlpha(50),
                      ), menuStyle: MenuStyle(
                        backgroundColor: MaterialStateProperty.resolveWith((states) => (cs.secondary)),
                      ),),

                      SizedBox(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                              color: cs.surface,
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                              borderRadius: BorderRadius.circular(45)
                          ),
                          child: Row(spacing: 15, crossAxisAlignment: CrossAxisAlignment.center, children: [
                            // Text('+', style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold, fontSize: size.width * .05),),
                            GestureDetector(child: Icon(Icons.add, color: cs.secondary), onTap: () {
                              setState(() {
                                grams += incrementalUnit;
                              });
                            },),
                            Text('$grams', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: size.width * .04),),
                            GestureDetector(child: Icon(Icons.remove, color: grams == minGrams ? Colors.grey.shade300 : cs.secondary), onTap: () {
                              setState(() {
                                grams -= incrementalUnit;
                              });
                            }),
                          ],),
                        ),
                      ),

                      /*SizedBox(
                        height: 40,
                        child: Row(textDirection: TextDirection.ltr, children: [
                          GestureDetector(
                            onTap: () {
                              if (grams != minGrams) {

                              }
                            },
                            child: Container(padding: EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: cs.secondary.withAlpha(50),
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(45), bottomLeft: Radius.circular(45)),
                            ),child: Container(
                              margin: EdgeInsets.only(bottom: 4),
                              child: Text('-', style: TextStyle(fontSize: size.width * .05, color: grams == minGrams ? Colors.grey.shade800 : Colors.black))
                            ),),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: cs.secondary.withAlpha(25),
                            ),

                            child: Text('$grams'),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                grams += incrementalUnit;
                              });
                            },
                            child: Container(padding: EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color: cs.secondary.withAlpha(50),
                                borderRadius: BorderRadius.only(topRight: Radius.circular(45), bottomRight: Radius.circular(45)),
                              ),child: Container(
                                  margin: EdgeInsets.only(bottom: 4),
                                  child: Text('+', style: TextStyle(fontSize: size.width * .05, color: grams == minGrams ? Colors.grey.shade800 : Colors.black))
                              ),
                            ),
                          ),
                        ],),
                      )*/
                    ],
                  ),),

                  if (cat == 'Appetizers' && menuItem['q'] != 1) Row(
                    children: [
                      SizedBox(width: 20,),
                      Text('${menuItem['q']} ${dic.piece}', style: TextStyle(fontSize: size.width * .045, fontWeight: FontWeight.bold), textAlign: TextAlign.start,),
                    ],
                  ),

                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    decoration: optionsDecoration.copyWith(color: cs.surface),
                    child: TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: dic.mv_notes,
                        fillColor: cs.surface,
                        filled: true
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom / 2,)
                ],
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 15, top: 15, left: 20, right: 20),
            decoration: BoxDecoration(
              color: cs.surface,
              boxShadow: [
                BoxShadow(color: Colors.grey.shade300, spreadRadius: 5, blurRadius: 10)
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop({
                      'q' : orderQ,
                      'ppi' : price,
                      'bt' : cat != 'Hotdog' && cat != 'Appetizers' ? breadType : null,
                      'pt' : cat != 'Hotdog' && cat != 'Appetizers' ? pattyType : null,
                      'ft' : isMeal && cat != 'Appetizers'? friesType : null,
                      'an' : notesController.text,
                      'g' : cat != 'Hotdog' && cat != 'Appetizers' ? grams : null,
                      'apq' : cat == 'Appetizers' ? menuItem['q'] : null,
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.secondary,
                      borderRadius: BorderRadius.circular(45)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 10,
                      children: [
                        Text(dic.mv_post, style: TextStyle(color: cs.surface, fontSize: size.width * .04125),),
                        FaIcon(FontAwesomeIcons.cartShopping, color: cs.surface, size: 12,),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(45)
                  ),
                  child: Row(spacing: 15, crossAxisAlignment: CrossAxisAlignment.center, children: [
                    // Text('+', style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold, fontSize: size.width * .05),),
                    GestureDetector(child: Icon(Icons.add, color: cs.secondary), onTap: () {
                      setState(() {
                        orderQ += 1;
                      });
                    },),
                    Text('$orderQ', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: size.width * .04),),
                    GestureDetector(child: Icon(Icons.remove, color: orderQ == 1 ? Colors.grey.shade300 : cs.secondary), onTap: () {
                      setState(() {
                        if (orderQ > 1) {
                          orderQ --;
                        }
                      });
                    }),
                  ],),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    is65Bun.dispose();
    isFitBun.dispose();
    isPotatoBun.dispose();
    isNormalFries.dispose();
    isCurly.dispose();
    isWedges.dispose();
    friesOptionsAnimation.dispose();
    isMealAnimation.dispose();
    isSandwichAnimation.dispose();
    r2Animation.dispose();
    r3Animation.dispose();
  }
}

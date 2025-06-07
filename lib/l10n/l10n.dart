import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_ar.dart';
import 'l10n_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n? of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n);
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'login / signup'**
  String get login;

  /// No description provided for @google_button.
  ///
  /// In en, this message translates to:
  /// **'continue with Google'**
  String get google_button;

  /// No description provided for @facebook_button.
  ///
  /// In en, this message translates to:
  /// **'Login with Facebook'**
  String get facebook_button;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Route 65'**
  String get app_name;

  /// No description provided for @completion.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get completion;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'continue'**
  String get continue_;

  /// No description provided for @name_error.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid name'**
  String get name_error;

  /// No description provided for @phone_check.
  ///
  /// In en, this message translates to:
  /// **'Verify phone number'**
  String get phone_check;

  /// No description provided for @check_phone.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get check_phone;

  /// No description provided for @enter_phone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enter_phone;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'previous'**
  String get previous;

  /// No description provided for @code_auth_err.
  ///
  /// In en, this message translates to:
  /// **'Check verification code'**
  String get code_auth_err;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Choose area'**
  String get location;

  /// No description provided for @current_location.
  ///
  /// In en, this message translates to:
  /// **'Delivery location to '**
  String get current_location;

  /// No description provided for @no_orders.
  ///
  /// In en, this message translates to:
  /// **'orders'**
  String get no_orders;

  /// No description provided for @congrats.
  ///
  /// In en, this message translates to:
  /// **'Congrats, you points now are -1 -2 🥳'**
  String get congrats;

  /// No description provided for @qr_scan_err.
  ///
  /// In en, this message translates to:
  /// **'This code has been scanned before'**
  String get qr_scan_err;

  /// No description provided for @get_back.
  ///
  /// In en, this message translates to:
  /// **'continue'**
  String get get_back;

  /// No description provided for @use_voucher.
  ///
  /// In en, this message translates to:
  /// **'use discount voucher %'**
  String get use_voucher;

  /// No description provided for @check_voucher.
  ///
  /// In en, this message translates to:
  /// **'check'**
  String get check_voucher;

  /// No description provided for @total_price.
  ///
  /// In en, this message translates to:
  /// **'total price'**
  String get total_price;

  /// No description provided for @voucher_value.
  ///
  /// In en, this message translates to:
  /// **'discount value'**
  String get voucher_value;

  /// No description provided for @price_after_discount.
  ///
  /// In en, this message translates to:
  /// **'price after discount'**
  String get price_after_discount;

  /// No description provided for @tables.
  ///
  /// In en, this message translates to:
  /// **'dining room'**
  String get tables;

  /// No description provided for @occupied.
  ///
  /// In en, this message translates to:
  /// **'occupied'**
  String get occupied;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'free'**
  String get free;

  /// No description provided for @confirm_order_title.
  ///
  /// In en, this message translates to:
  /// **'Confirm order'**
  String get confirm_order_title;

  /// No description provided for @confirm_order.
  ///
  /// In en, this message translates to:
  /// **'confirm order'**
  String get confirm_order;

  /// No description provided for @error_while_pushing_order.
  ///
  /// In en, this message translates to:
  /// **'error happened while sending order'**
  String get error_while_pushing_order;

  /// No description provided for @voucher_dne.
  ///
  /// In en, this message translates to:
  /// **'This voucher does not exist'**
  String get voucher_dne;

  /// No description provided for @order_status_preparing.
  ///
  /// In en, this message translates to:
  /// **'Your order is being prepared'**
  String get order_status_preparing;

  /// No description provided for @order_status_on_road.
  ///
  /// In en, this message translates to:
  /// **'Your order is on the road!'**
  String get order_status_on_road;

  /// No description provided for @no_additional_notes.
  ///
  /// In en, this message translates to:
  /// **'No additional notes'**
  String get no_additional_notes;

  /// No description provided for @jd.
  ///
  /// In en, this message translates to:
  /// **'JD'**
  String get jd;

  /// No description provided for @delivery_fee.
  ///
  /// In en, this message translates to:
  /// **'delivery fees'**
  String get delivery_fee;

  /// No description provided for @total_with_delivery.
  ///
  /// In en, this message translates to:
  /// **'total with delivery fees'**
  String get total_with_delivery;

  /// No description provided for @takeaway.
  ///
  /// In en, this message translates to:
  /// **'take away'**
  String get takeaway;

  /// No description provided for @takeaway_ps.
  ///
  /// In en, this message translates to:
  /// **'Pizza st. branch'**
  String get takeaway_ps;

  /// No description provided for @takeaway_qs.
  ///
  /// In en, this message translates to:
  /// **'Arab Revolt Plaza branch'**
  String get takeaway_qs;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'delivery'**
  String get delivery;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'phone'**
  String get phone;

  /// No description provided for @voucher.
  ///
  /// In en, this message translates to:
  /// **'voucher'**
  String get voucher;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search locations ...'**
  String get search;

  /// No description provided for @search_r_t.
  ///
  /// In en, this message translates to:
  /// **'delivery to'**
  String get search_r_t;

  /// No description provided for @close_place.
  ///
  /// In en, this message translates to:
  /// **'close to ...'**
  String get close_place;

  /// No description provided for @your_order_t.
  ///
  /// In en, this message translates to:
  /// **'Your order is being prepared!'**
  String get your_order_t;

  /// No description provided for @login_error.
  ///
  /// In en, this message translates to:
  /// **'Problem happened while trying to login, check your connection and try again later'**
  String get login_error;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'finish'**
  String get finish;

  /// No description provided for @account_finished.
  ///
  /// In en, this message translates to:
  /// **'Your account created successfully!'**
  String get account_finished;

  /// No description provided for @tokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens : '**
  String get tokens;

  /// No description provided for @points_1.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get points_1;

  /// No description provided for @points_2.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get points_2;

  /// No description provided for @vouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get vouchers;

  /// No description provided for @chatbot_title.
  ///
  /// In en, this message translates to:
  /// **'Route 65 ChatBot'**
  String get chatbot_title;

  /// No description provided for @chatbot_input_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter a message ...'**
  String get chatbot_input_hint;

  /// No description provided for @no_internet.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again'**
  String get no_internet;

  /// No description provided for @send_code_err.
  ///
  /// In en, this message translates to:
  /// **'Failed to send authentication code'**
  String get send_code_err;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try again?'**
  String get try_again;

  /// No description provided for @div1.
  ///
  /// In en, this message translates to:
  /// **'menu'**
  String get div1;

  /// No description provided for @beef.
  ///
  /// In en, this message translates to:
  /// **'Beef Meals'**
  String get beef;

  /// No description provided for @chicken.
  ///
  /// In en, this message translates to:
  /// **'Chicken Meals'**
  String get chicken;

  /// No description provided for @hotdogs.
  ///
  /// In en, this message translates to:
  /// **'Hotdogs'**
  String get hotdogs;

  /// No description provided for @appetizers.
  ///
  /// In en, this message translates to:
  /// **'Appetizers'**
  String get appetizers;

  /// No description provided for @show_more.
  ///
  /// In en, this message translates to:
  /// **'Show more ...'**
  String get show_more;

  /// No description provided for @robot_sc.
  ///
  /// In en, this message translates to:
  /// **'start chat ...'**
  String get robot_sc;

  /// No description provided for @piece.
  ///
  /// In en, this message translates to:
  /// **'pieces'**
  String get piece;

  /// No description provided for @continue_shopping.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping!'**
  String get continue_shopping;

  /// No description provided for @meal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get meal;

  /// No description provided for @pnormal.
  ///
  /// In en, this message translates to:
  /// **'normal fries'**
  String get pnormal;

  /// No description provided for @pwidges.
  ///
  /// In en, this message translates to:
  /// **'potato widges'**
  String get pwidges;

  /// No description provided for @pcurly.
  ///
  /// In en, this message translates to:
  /// **'curly fries'**
  String get pcurly;

  /// No description provided for @pa_normal.
  ///
  /// In en, this message translates to:
  /// **'normal patty'**
  String get pa_normal;

  /// No description provided for @pa_special.
  ///
  /// In en, this message translates to:
  /// **'special'**
  String get pa_special;

  /// No description provided for @pa_smashed.
  ///
  /// In en, this message translates to:
  /// **'smashed'**
  String get pa_smashed;

  /// No description provided for @mv_notes.
  ///
  /// In en, this message translates to:
  /// **'Add additional notes ...'**
  String get mv_notes;

  /// No description provided for @mv_post.
  ///
  /// In en, this message translates to:
  /// **'Add item to cart'**
  String get mv_post;

  /// No description provided for @your_basket.
  ///
  /// In en, this message translates to:
  /// **'Your Basket'**
  String get your_basket;

  /// No description provided for @bv_pt.
  ///
  /// In en, this message translates to:
  /// **'patty type : '**
  String get bv_pt;

  /// No description provided for @bv_ft.
  ///
  /// In en, this message translates to:
  /// **'fries type : '**
  String get bv_ft;

  /// No description provided for @bv_ot.
  ///
  /// In en, this message translates to:
  /// **'order type : '**
  String get bv_ot;

  /// No description provided for @bv_bt.
  ///
  /// In en, this message translates to:
  /// **'bread type : '**
  String get bv_bt;

  /// No description provided for @gram.
  ///
  /// In en, this message translates to:
  /// **'gram'**
  String get gram;

  /// No description provided for @b_potbun.
  ///
  /// In en, this message translates to:
  /// **'Potato Bun'**
  String get b_potbun;

  /// No description provided for @b_65.
  ///
  /// In en, this message translates to:
  /// **'65 Bread'**
  String get b_65;

  /// No description provided for @b_fit.
  ///
  /// In en, this message translates to:
  /// **'Fit Bread'**
  String get b_fit;

  /// No description provided for @basket_empty.
  ///
  /// In en, this message translates to:
  /// **'Your basket is empty'**
  String get basket_empty;

  /// No description provided for @map_t1.
  ///
  /// In en, this message translates to:
  /// **'Here are our branches in Aqaba!'**
  String get map_t1;

  /// No description provided for @sandwich.
  ///
  /// In en, this message translates to:
  /// **'Sandwich'**
  String get sandwich;

  /// No description provided for @a3.
  ///
  /// In en, this message translates to:
  /// **'3rd Area'**
  String get a3;

  /// No description provided for @a4.
  ///
  /// In en, this message translates to:
  /// **'4th Area'**
  String get a4;

  /// No description provided for @a5.
  ///
  /// In en, this message translates to:
  /// **'5th Area'**
  String get a5;

  /// No description provided for @a6.
  ///
  /// In en, this message translates to:
  /// **'6th Area'**
  String get a6;

  /// No description provided for @a7.
  ///
  /// In en, this message translates to:
  /// **'7th Area'**
  String get a7;

  /// No description provided for @a8.
  ///
  /// In en, this message translates to:
  /// **'8th Area'**
  String get a8;

  /// No description provided for @a9.
  ///
  /// In en, this message translates to:
  /// **'9th Area'**
  String get a9;

  /// No description provided for @a10.
  ///
  /// In en, this message translates to:
  /// **'10th Area'**
  String get a10;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'Al-Mahdoud'**
  String get am;

  /// No description provided for @aa.
  ///
  /// In en, this message translates to:
  /// **'Al-A\'lameyeh'**
  String get aa;

  /// No description provided for @ah.
  ///
  /// In en, this message translates to:
  /// **'Al-harafeyeh'**
  String get ah;

  /// No description provided for @as.
  ///
  /// In en, this message translates to:
  /// **'Sakan Al-Ateba\''**
  String get as;

  /// No description provided for @ak.
  ///
  /// In en, this message translates to:
  /// **'Al-Khazan'**
  String get ak;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return L10nAr();
    case 'en': return L10nEn();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

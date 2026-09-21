import 'package:flutter/material.dart';

class IconMapper {
  static IconData getIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'directions_car':
        return Icons.directions_car;
      case 'house':
        return Icons.house;
      case 'receipt':
        return Icons.receipt;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'subscriptions':
        return Icons.subscriptions;
      case 'spa':
        return Icons.spa;
      case 'devices':
        return Icons.devices;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'trending_up':
        return Icons.trending_up;
      case 'category':
        return Icons.category;
      case 'work':
        return Icons.work;
      case 'computer':
        return Icons.computer;
      case 'business_center':
        return Icons.business_center;
      case 'account_balance':
        return Icons.account_balance;
      case 'replay':
        return Icons.replay;
      case 'redeem':
        return Icons.redeem;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }
}

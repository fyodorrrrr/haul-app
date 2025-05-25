import 'package:flutter/material.dart';
import '../models/help_models.dart';

final List<HelpCategory> helpCategories = [
  // ... paste all the help categories data from above
];

final List<HelpItem> helpItems = helpCategories
    .expand((category) => category.items)
    .toList();
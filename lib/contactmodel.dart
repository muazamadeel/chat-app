import 'package:flutter/material.dart';

class Contactmodel {
  String? image;
  String? name;
  String? text;
  IconData? accept;
  IconData? reject;

  Contactmodel({
    this.image,
    this.name,
    this.text,
    this.accept,
    this.reject,
  });

  static List<Contactmodel> mylist = [
    Contactmodel(
      image: "images/person2.jpeg",
      name: "Alex Linderson",
      text: "Life is beautiful",
      accept: Icons.call_received,
      reject: Icons.call_end_rounded,
    ),
    Contactmodel(
      image: "images/person3.jpeg",
      name: "Team Align",
      text: "Be Your own hero.",
      accept: Icons.call_received,
      reject: Icons.call_end_rounded,
    ),
    Contactmodel(
      image: "images/quote2.jpeg",
      name: "John Ahraham",
      text: "keep Working",
      accept: Icons.call_received,
      reject: Icons.call_end_rounded,
    ),
    Contactmodel(
      image: "images/person2.jpeg",
      name: "Alex Linderson",
      text: "Never Give Up",
      accept: Icons.call_received,
      reject: Icons.call_end_rounded,
    ),
    Contactmodel(
      image: "images/person2.jpeg",
      name: "Alex Linderson",
      text: "How are you today?",
      accept: Icons.call_received,
      reject: Icons.call_end_rounded,
    ),
    Contactmodel(
      image: "images/person2.jpeg",
      name: "Alex Linderson",
      text: "How are you today?",
      accept: Icons.call_received,
      reject: Icons.call_end_rounded,
    ),
    Contactmodel(
      image: "images/person2.jpeg",
      name: "Alex Linderson",
      text: "How are you today?",
      accept: Icons.call_received,
      reject: Icons.call_end_rounded,
    ),
  ];
}

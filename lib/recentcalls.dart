import 'package:flutter/material.dart';

class recentcalls {
  String? image;
  String? name;
  IconData? Icon;
  String? day;
  String? time;
  IconData? audio;
  IconData? vedio;

  recentcalls(
      {this.image,
      this.name,
      this.Icon,
      this.day,
      this.time,
      this.audio,
      this.vedio});

  static List<recentcalls> mylist = [
    recentcalls(
        image: "images/person2.jpeg",
        name: "Team Align",
        Icon: Icons.call,
        day: "Today,",
        time: "09:30 AM",
        audio: Icons.call,
        vedio: Icons.video_call),
    recentcalls(
        image: "images/person3.jpeg",
        name: "Alex Linderson",
        Icon: Icons.call,
        day: "Today,",
        time: "07:30 AM",
        audio: Icons.call,
        vedio: Icons.video_call),
    recentcalls(
        image: "images/quote2.jpeg",
        name: "Sabila Sayma",
        Icon: Icons.call,
        day: "Yesterday,",
        time: "09:30 AM",
        audio: Icons.call,
        vedio: Icons.video_call),
    recentcalls(
        image: "images/person2.jpeg",
        name: "John Abraham",
        Icon: Icons.call,
        day: "03/07/22,",
        time: "09:30 AM",
        audio: Icons.call,
        vedio: Icons.video_call),
    recentcalls(
        image: "images/person3.jpeg",
        name: "John Borino",
        Icon: Icons.call,
        day: "Monday,",
        time: "09:30 AM",
        audio: Icons.call,
        vedio: Icons.video_call),
    recentcalls(
        image: "images/person2.jpeg",
        name: "Team Align",
        Icon: Icons.call,
        day: "Today,",
        time: "09:30 AM",
        audio: Icons.call,
        vedio: Icons.video_call),
    recentcalls(
        image: "images/person3.jpeg",
        name: "Alex Linderson",
        Icon: Icons.call,
        day: "Today,",
        time: "07:30 AM",
        audio: Icons.call,
        vedio: Icons.video_call),
    recentcalls(
        image: "images/quote2.jpeg",
        name: "Sabila Sayma",
        Icon: Icons.call,
        day: "Yesterday,",
        time: "09:30 AM",
        audio: Icons.call,
        vedio: Icons.video_call),
    recentcalls(
        image: "images/person2.jpeg",
        name: "John Abraham",
        Icon: Icons.call,
        day: "03/07/22,",
        time: "09:30 AM",
        audio: Icons.call,
        vedio: Icons.video_call),
    recentcalls(
        image: "images/person3.jpeg",
        name: "John Borino",
        Icon: Icons.call,
        day: "Monday,",
        time: "09:30 AM",
        audio: Icons.call,
        vedio: Icons.video_call),
  ];
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medcave/config/colors/appcolor.dart';

class FontStyles {
  static TextStyle titleHero = TextStyle(
    color: AppColor.backgroundWhite,
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -(72 * .02), // Letter spacing is -2% of the font size
    height: 1.2, // Line spacing is 120% of the font size
  );

  static TextStyle titlePage = TextStyle(
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -(48 * .02), // Letter spacing is -2% of the font size
    height: 1.2, // Line spacing is 120% of the font size
  );

  static TextStyle subTitle = TextStyle(
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0, // Letter spacing is 0% of the font size
    height: 1.2, // Line spacing is 120% of the font size
  );

  static TextStyle heading = TextStyle(
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -(24 * .02), // Letter spacing is -2% of the font size
    height: 1.2, // Line spacing is 120% of the font size
  );

  static TextStyle subHeading = TextStyle(
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0, // Letter spacing is 0% of the font size
    height: 1.2, // Line spacing is 120% of the font size
  );

  static TextStyle bodyBase = TextStyle(
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0, // Letter spacing is 0% of the font size
    height: 1.4, // Line spacing is 140% of the font size
  );

  static TextStyle bodyStrong = TextStyle(
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0, // Letter spacing is 0% of the font size
    height: 1.4, // Line spacing is 140% of the font size
  );

  static TextStyle bodyEmphasis = TextStyle(
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
    fontSize: 16,
    fontStyle: FontStyle.italic,
    letterSpacing: 0, // Letter spacing is 0% of the font size
    height: 1.4, // Line spacing is 140% of the font size
  );

  static TextStyle bodyLink = TextStyle(
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
    fontSize: 16,
    decoration: TextDecoration.underline,
    fontWeight: FontWeight.w400,
    letterSpacing: 0, // Letter spacing is 0% of the font size
    height: 1.4, // Line spacing is 140% of the font size
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0, // Letter spacing is 0% of the font size
    height: 1.4, // Line spacing is 140% of the font size
  );

  static TextStyle bodySmallStrong = TextStyle(
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0, // Letter spacing is 0% of the font size
    height: 1.4, // Line spacing is 140% of the font size
  );
}

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart'; // Correct import for hijri package
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'notification_service.dart';

// --- App State Management ---
class AppProvider with ChangeNotifier {
  String _selectedCity = "پێنجوێن";
  int _selectedThemeIndex = 0;

  String get selectedCity => _selectedCity;
  int get selectedThemeIndex => _selectedThemeIndex;

  ThemeData get currentTheme => themes[_selectedThemeIndex];
  Color get neumorphicColor => _selectedThemeIndex == 1
      ? const Color(0xFF2E2E2E)
      : const Color(0xFFE0E5EC);

  void setCity(String city) {
    _selectedCity = city;
    notifyListeners();
  }

  void setTheme(int themeIndex) {
    _selectedThemeIndex = themeIndex;
    notifyListeners();
  }
}

// --- Data ---
final Map<String, List<String>> allPrayerTimes = {
  "پێنجوێن": ["05:30", "06:54", "12:15", "15:12", "17:36", "18:56"],
  "سلێمانی": ["05:32", "06:56", "12:17", "15:14", "17:38", "18:58"],
  "هەولێر": ["05:38", "07:02", "12:23", "15:20", "17:44", "19:04"],
  "دهۆک": ["05:42", "07:06", "12:27", "15:24", "17:48", "19:08"],
  "کەرکوک": ["05:40", "07:04", "12:25", "15:22", "17:46", "19:06"],
  "هەڵەبجە": ["05:31", "06:55", "12:16", "15:13", "17:37", "18:57"],
};

final List<ThemeData> themes = [
  ThemeData(
      fontFamily: 'Tahoma',
      scaffoldBackgroundColor: const Color(0xFFE0E5EC),
      appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD1D5DB), foregroundColor: Colors.black87),
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
  ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Tahoma',
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F), foregroundColor: Colors.white),
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent, brightness: Brightness.dark)),
  ThemeData(
      fontFamily: 'Tahoma',
      scaffoldBackgroundColor: const Color(0xFFF0FFF0),
      appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E8B57), foregroundColor: Colors.white),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E8B57))),
  ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, secondary: Colors.blueAccent)),
  ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
          secondary: Colors.purpleAccent)),
  ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange, secondary: Colors.orangeAccent)),
  ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
          secondary: Colors.redAccent)),
];

final List<String> prayerNames = [
  "بەیانی",
  "خۆرهەڵاتن",
  "نیوەڕۆ",
  "عەسر",
  "ئێوارە",
  "خەوتنان"
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: const PrayerTimesApp(),
    ),
  );
}

class PrayerTimesApp extends StatelessWidget {
  const PrayerTimesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          //locale: const Locale('ku', 'IQ'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          //supportedLocales: const [Locale('ar', 'IQ'), Locale('ku', 'IQ')],
          theme: appProvider.currentTheme,
          home: const PrayerHomePage(),
        );
      },
    );
  }
}

class PrayerHomePage extends StatefulWidget {
  const PrayerHomePage({super.key});

  @override
  State<PrayerHomePage> createState() => _PrayerHomePageState();
}

class _PrayerHomePageState extends State<PrayerHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _now = DateTime.now();
  String? activeAthan;
  final AudioPlayer audioPlayer = AudioPlayer();
  String selectedMuezzin = "madina.mp3";
  Map<String, bool> enabledPrayers = {
    "بەیانی": false,
    "نیوەڕۆ": false,
    "عەسر": false,
    "ئێوارە": false,
    "خەوتنان": false
  };

  @override
  void initState() {
    super.initState();
    // Set Kurdish localization for Hijri calendar
    HijriCalendar.setLocal('ar');
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _now = DateTime.now());
        _checkAthanTime();
      }
    });
  }

  void _checkAthanTime() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final prayerTimes = allPrayerTimes[appProvider.selectedCity]!;
    String currentTime = DateFormat("HH:mm").format(_now);
    if (_now.second == 0) {
      for (int i = 0; i < prayerNames.length; i++) {
        if (prayerNames[i] == "خۆرهەڵاتن") continue;
        if (prayerTimes[i] == currentTime &&
            enabledPrayers[prayerNames[i]] == true) {
          _playAthan();
        }
      }
    }
  }

  Future<void> _playAthan() async {
    try {
      // await _audioPlayer.stop();
      // await _audioPlayer.play(AssetSource('audio/$selectedMuezzin'));
      developer.log('Athan time!', name: 'prayer_app.athan');
    } catch (e, s) {
      developer.log('Error playing audio',
          name: 'my_app.audio', level: 1000, error: e, stackTrace: s);
    }
  }

  Future<void> _schedulePrayerNotifications() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final prayerTimes = allPrayerTimes[appProvider.selectedCity]!;

    // سڕینەوەی notification ـەکانی پێشوو
    await NotificationService.cancelAll();

    // شەدوڵکردنی notification بۆ بانگە چالاکەکان
    for (int i = 0; i < prayerNames.length; i++) {
      String prayerName = prayerNames[i];

      if (prayerName == "خۆرهەڵاتن") continue; // خۆرهەڵاتن بانگی نییە

      if (enabledPrayers[prayerName] == true) {
        List<String> parts = prayerTimes[i].split(':');
        DateTime scheduledTime = DateTime(
          _now.year,
          _now.month,
          _now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        // ئەگەر کاتەکە تێپەڕیوە، بۆ سبەی شەدوڵی بکە
        if (scheduledTime.isBefore(_now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        await NotificationService.scheduleAthan(
          id: i,
          title: prayerName,
          scheduledTime: scheduledTime,
          soundFile: selectedMuezzin,
        );
      }
    }
  }

  String toKu(String n) => n
      .replaceAll('0', '٠')
      .replaceAll('1', '١')
      .replaceAll('2', '٢')
      .replaceAll('3', '٣')
      .replaceAll('4', '٤')
      .replaceAll('5', '٥')
      .replaceAll('6', '٦')
      .replaceAll('7', '٧')
      .replaceAll('8', '٨')
      .replaceAll('9', '٩');

  Map<String, dynamic> getNextPrayerInfo() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final prayerTimes = allPrayerTimes[appProvider.selectedCity]!;
    for (int i = 0; i < prayerTimes.length; i++) {
      List<String> parts = prayerTimes[i].split(':');
      DateTime pTime = DateTime(_now.year, _now.month, _now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      if (pTime.isAfter(_now)) {
        return {"name": prayerNames[i], "diff": pTime.difference(_now)};
      }
    }
    List<String> tomorrowParts = prayerTimes[0].split(':');
    DateTime tomorrowPrayerTime = DateTime(_now.year, _now.month, _now.day + 1,
        int.parse(tomorrowParts[0]), int.parse(tomorrowParts[1]));
    return {
      "name": prayerNames[0],
      "diff": tomorrowPrayerTime.difference(_now)
    };
  }

  String formatDuration(Duration d) =>
      "${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  String getHijriDate() {
    final hijri = HijriCalendar.now();
    final monthsKurdish = [
      'موحەڕڕەم',
      'سەفەر',
      'ڕەبیعی یەکەم',
      'ڕەبیعی دووەم',
      'جومادەڵئەووەڵ',
      'جومادەڵئاخیر',
      'ڕەجەب',
      'شەعبان',
      'ڕەمەزان',
      'شەووال',
      'زولقەعدە',
      'زولحیججە'
    ];
    return "${toKu(hijri.hDay.toString())} ${monthsKurdish[hijri.hMonth - 1]} ${toKu(hijri.hYear.toString())}";
  }

  String getKurdiAndGregorian() =>
      "زایینى: ${toKu(DateFormat("d/M/yyyy").format(_now))}  |  کوردى: ${toKu("١٨ـى ڕێبەندانى ${(_now.year + 701)}")}";

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final prayerTimes = allPrayerTimes[appProvider.selectedCity]!;
    var next = getNextPrayerInfo();
    String time12h = DateFormat("hh:mm:ss").format(_now);
    String period = _now.hour >= 12 ? "PM" : "AM";

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: appProvider.neumorphicColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 50,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Row(children: [
          const Icon(Icons.mosque, size: 28),
          const SizedBox(width: 8),
          Text("کاتەکانی بانگی ${appProvider.selectedCity}",
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          )
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(children: [
        const SizedBox(height: 10),
        Text("${toKu(time12h)} $period",
            style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB8860B),
                fontFeatures: [FontFeature.tabularFigures()])),
        const SizedBox(height: 5),
        Text(getHijriDate(),
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green)), // Used to be toKu(getHijriDate())
        const SizedBox(height: 2),
        FittedBox(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(getKurdiAndGregorian(),
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black54)))),
        const SizedBox(height: 15),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
              decoration: BoxDecoration(
                  color: appProvider.neumorphicColor,
                  borderRadius: BorderRadius.circular(13)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(toKu(formatDuration(next['diff'])),
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary)),
                const SizedBox(width: 10),
                Text("بۆ ${next['name']}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600))
              ])),
        ),
        const SizedBox(height: 10),
        Expanded(
            child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                itemCount: 6,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, i) {
                  String name = prayerNames[i];
                  if (name == "خۆرهەڵاتن") {
                    return _buildSunriseCard(prayerTimes[i]);
                  }
                  return NeumorphicPrayerCard(
                    name: name,
                    time: prayerTimes[i],
                    isSelected: activeAthan == name,
                    isSoundEnabled: enabledPrayers[name] ?? false,
                    onTap: () => setState(() => activeAthan = name),
                    onSoundToggle: () {
                      setState(() {
                        enabledPrayers[name] = !(enabledPrayers[name] ?? false);
                      });
                      _schedulePrayerNotifications();
                    },
                    toKu: toKu,
                  );
                })),
      ]),
    );
  }

  Widget _buildSunriseCard(String time) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
              colors: [Colors.yellow.shade700, Colors.orange.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: Container(
          decoration: BoxDecoration(
              color:
                  context.watch<AppProvider>().neumorphicColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10)),
          child: ListTile(
              visualDensity: VisualDensity.compact,
              enabled: false,
              title: const Text("خۆرهەڵاتن",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB8860B))),
              subtitle: Text(toKu(time),
                  style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFB8860B),
                      fontWeight: FontWeight.bold)),
              trailing: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(colors: [
                        Colors.yellow,
                        Colors.orange,
                        Colors.yellowAccent
                      ], stops: [
                        0.0,
                        0.5,
                        1.0
                      ], tileMode: TileMode.mirror)
                          .createShader(bounds),
                  child: const Icon(Icons.wb_sunny,
                      color: Colors.white, size: 28)))),
    );
  }

  Widget _buildDrawer() => Drawer(
      backgroundColor: context.watch<AppProvider>().neumorphicColor,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(children: [
          const SizedBox(height: 20),
          const Text("ڕێکخستن",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          CustomExpansionTile(
              title: "شارەکان",
              icon: Icons.location_city,
              children: allPrayerTimes.keys
                  .map((city) => ListTile(
                      title: Text(city),
                      trailing: Icon(
                          context.watch<AppProvider>().selectedCity == city
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: Theme.of(context).colorScheme.secondary),
                      onTap: () => context.read<AppProvider>().setCity(city)))
                  .toList()),
          CustomExpansionTile(
              title: "دەنگی بانگ",
              icon: Icons.mic,
              children: ["madina.mp3", "kwait.mp3", "kamal_rauf.mp3"]
                  .map((file) => ListTile(
                      title: Text(file.split('.').first.replaceAll('_', ' ')),
                      trailing: Icon(
                          selectedMuezzin == file
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: Theme.of(context).colorScheme.secondary),
                      onTap: () => setState(() => selectedMuezzin = file)))
                  .toList()),
          CustomExpansionTile(
              title: "ڕووکار",
              icon: Icons.palette,
              children: List.generate(
                  7,
                  (index) => ListTile(
                      title: Text("ڕووکاری ${index + 1}"),
                      trailing: Icon(
                          context.watch<AppProvider>().selectedThemeIndex ==
                                  index
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: Theme.of(context).colorScheme.secondary),
                      onTap: () =>
                          context.read<AppProvider>().setTheme(index)))),
          ListTile(
              leading: const Icon(Icons.play_circle, color: Colors.red),
              title: const Text("یوتیوب"),
              onTap: () =>
                  launchUrl(Uri.parse('https://youtube.com/@daryan111'))),
        ]),
      ));
}

// --- Custom Widgets for Final Phase ---

class NeumorphicPrayerCard extends StatelessWidget {
  final String name;
  final String time;
  final bool isSelected;
  final bool isSoundEnabled;
  final VoidCallback onTap;
  final VoidCallback onSoundToggle;
  final String Function(String) toKu;

  const NeumorphicPrayerCard(
      {super.key,
      required this.name,
      required this.time,
      required this.isSelected,
      required this.isSoundEnabled,
      required this.onTap,
      required this.onSoundToggle,
      required this.toKu});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final color = appProvider.neumorphicColor;
    final isDark = appProvider.selectedThemeIndex == 1;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSoundEnabled ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                        color, Theme.of(context).colorScheme.secondary, value)!,
                    Color.lerp(
                        color,
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.5),
                        value)!
                  ]),
              boxShadow: isSelected
                  ? []
                  : [
                      BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.white.withOpacity(0.5),
                          offset: const Offset(-4, -4),
                          blurRadius: 4),
                      BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.grey.shade400,
                          offset: const Offset(4, 4),
                          blurRadius: 4),
                    ]),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(13)),
        child: ListTile(
          onTap: onTap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          visualDensity: VisualDensity.compact,
          title: Text(name,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.secondary
                      : null)),
          subtitle: Text(toKu(time),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.secondary)),
          trailing: NeumorphicIconButton(
              isToggled: isSoundEnabled, onToggle: onSoundToggle),
        ),
      ),
    );
  }
}

class NeumorphicIconButton extends StatelessWidget {
  final bool isToggled;
  final VoidCallback onToggle;
  const NeumorphicIconButton(
      {super.key, required this.isToggled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final color = appProvider.neumorphicColor;
    final isDark = appProvider.selectedThemeIndex == 1;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        width: 44,
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isToggled
                ? [
                    BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.grey.shade400,
                        offset: const Offset(2, 2),
                        blurRadius: 2,
                        spreadRadius: 1),
                    BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.white,
                        offset: const Offset(-2, -2),
                        blurRadius: 2,
                        spreadRadius: 1),
                  ]
                : [
                    BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.white,
                        offset: const Offset(-3, -3),
                        blurRadius: 3),
                    BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.grey.shade400,
                        offset: const Offset(3, 3),
                        blurRadius: 3),
                  ]),
        child: Icon(isToggled ? Icons.volume_up : Icons.volume_off,
            color: isToggled
                ? Theme.of(context).colorScheme.secondary
                : Colors.grey.shade600),
      ),
    );
  }
}

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const CustomExpansionTile(
      {super.key,
      required this.title,
      required this.icon,
      required this.children});

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);
    _widthAnimation = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _toggle,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                width: MediaQuery.of(context).size.width *
                    0.85 *
                    _widthAnimation.value,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          blurRadius: 5,
                          offset: const Offset(2, 2)),
                    ]),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(widget.icon),
                      Text(widget.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      RotationTransition(
                          turns:
                              Tween(begin: 0.0, end: 0.25).animate(_controller),
                          child: const Icon(Icons.chevron_right))
                    ]),
              ),
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _controller.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.children),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

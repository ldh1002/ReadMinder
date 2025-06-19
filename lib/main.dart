import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/diary_entry.dart';
import 'dart:math';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(DiaryEntryAdapter());
  await Hive.openBox<DiaryEntry>('entries');
  runApp(const ReadMindApp());
}

/// 앱 진입점
class ReadMindApp extends StatelessWidget {
  const ReadMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReadMind',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// 스플래시 화면 (2초 후 메인 탭으로 이동)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainTabScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Read', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            Text('Minder', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('내 손 안의 작은 도서관', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

/// 메인 탭바: 일기 작성 / 기록보기 / 홈 / 분석 / 설정
class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});
  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 2;
  static const List<Widget> _pages = [
    DiaryEntryPage(),
    DiaryListPage(),
    HomeScreen(),
    AnalysisPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int i) => setState(() => _selectedIndex = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_note),  label: '독서 일기 작성'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book),  label: '기록보기'),
          BottomNavigationBarItem(icon: Icon(Icons.home),       label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart),  label: '분석'),
          BottomNavigationBarItem(icon: Icon(Icons.settings),   label: '설정'),
        ],
      ),
    );
  }
}

/// 독서 일기 작성 페이지
class DiaryEntryPage extends StatefulWidget {
  const DiaryEntryPage({super.key});
  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController(text: '30');
  DateTime _selectedDate  = DateTime.now();
  double   _readingMinutes = 30;

  /// 일기 저장
  void _saveEntry() async {
    final mins = int.tryParse(_minutesCtrl.text) ?? _readingMinutes.toInt();
    final entry = DiaryEntry(
      title:   _titleCtrl.text,
      date:    _selectedDate,
      minutes: mins,
      content: _contentCtrl.text,
      isFavorite: false,
    );
    await Hive.box<DiaryEntry>('entries').add(entry);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('일기 저장 완료!')));
    _titleCtrl.clear();
    _contentCtrl.clear();
    _minutesCtrl.text = '30';
    setState(() => _readingMinutes = 30);
  }

  /// 날짜 선택
  void _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('독서 일기 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('책 제목', style: TextStyle(fontSize:16,fontWeight: FontWeight.bold)),
            TextField(controller: _titleCtrl),
            const SizedBox(height:12),

            const Text('날짜', style: TextStyle(fontSize:16,fontWeight: FontWeight.bold)),
            Row(children: [
              Text('${_selectedDate.toLocal()}'.split(' ')[0]),
              const SizedBox(width:8),
              TextButton(onPressed: _pickDate, child: const Text('날짜 선택')),
            ]),
            const SizedBox(height:12),

            const Text('독서 시간 (분)', style: TextStyle(fontSize:16,fontWeight: FontWeight.bold)),
            Row(children: [
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _minutesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true),
                  onChanged: (v){
                    final val=int.tryParse(v);
                    if(val!=null) setState(()=>_readingMinutes=val.toDouble());
                  },
                ),
              ),
              const SizedBox(width:16),
              Expanded(child: Slider(
                value: _readingMinutes,
                min: 0, max: 180, divisions: 18,
                label: _readingMinutes.toInt().toString(),
                onChanged: (v){
                  setState(() {
                    _readingMinutes = v;
                    _minutesCtrl.text = v.toInt().toString();
                  });
                },
              )),
            ]),
            const SizedBox(height:12),

            const Text('감상 입력', style: TextStyle(fontSize:16,fontWeight: FontWeight.bold)),
            TextField(
              controller: _contentCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '감상을 자유롭게 작성하세요',
              ),
            ),
          ],
        )),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveEntry,
        icon: const Icon(Icons.save),
        label: const Text('저장하기'),
      ),
    );
  }
}

/// 상세보기 & 수정 페이지
class DiaryDetailPage extends StatefulWidget {
  final DiaryEntry entry;
  const DiaryDetailPage({super.key, required this.entry});
  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  late DiaryEntry _entry;
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _minutesCtrl;
  late double _readingMinutes;
  late DateTime _selectedDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _entry          = widget.entry;
    _titleCtrl      = TextEditingController(text: _entry.title);
    _contentCtrl    = TextEditingController(text: _entry.content);
    _readingMinutes = _entry.minutes.toDouble();
    _selectedDate   = _entry.date;
    _minutesCtrl    = TextEditingController(text: _entry.minutes.toString());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() => setState(() => _isEditing = !_isEditing);

  void _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  /// 수정된 내용 저장
  void _saveChanges() {
    setState(() {
      _entry.title   = _titleCtrl.text;
      _entry.content = _contentCtrl.text;
      _entry.minutes = int.tryParse(_minutesCtrl.text) ?? _readingMinutes.toInt();
      _entry.date    = _selectedDate;
      _entry.save();
      _isEditing = false;
    });
  }

  /// 삭제 확인
  void _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 일기를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('삭제')),
        ],
      ),
    );
    if (ok == true) {
      await _entry.delete();
      Navigator.pop(context);
    }
  }

  /// 즐겨찾기 토글
  void _toggleFavorite() {
    setState(() {
      _entry.isFavorite = !_entry.isFavorite;
      _entry.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '일기 수정' : _entry.title),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _isEditing ? _saveChanges : _toggleEdit,
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDelete),
          IconButton(
            icon: Icon(_entry.isFavorite ? Icons.star : Icons.star_border),
            color: Colors.amber,
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing) ...[
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: '책 제목'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Text('날짜: '),
                Text('${_selectedDate.toLocal()}'.split(' ')[0]),
                const SizedBox(width: 8),
                TextButton(onPressed: _pickDate, child: const Text('날짜 선택')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Text('읽은 시간: '),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _minutesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: '분'),
                    onChanged: (v) {
                      final m = int.tryParse(v);
                      if (m != null) setState(() => _readingMinutes = m.toDouble());
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Slider(
                  value: _readingMinutes,
                  min: 0,
                  max: 180,
                  divisions: 18,
                  label: _readingMinutes.toInt().toString(),
                  onChanged: (v) {
                    setState(() {
                      _readingMinutes = v;
                      _minutesCtrl.text = v.toInt().toString();
                    });
                  },
                )),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _contentCtrl,
                maxLines: 5,
                decoration: const InputDecoration(labelText: '감상'),
              ),
            ] else ...[
              Row(children: [
                const Icon(Icons.book),
                const SizedBox(width: 8),
                Expanded(child: Text('책 제목: ${_entry.title}')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text('날짜: ${_entry.date.toLocal().toString().split(' ')[0]}'),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text('읽은 시간: ${_entry.minutes}분'),
              ]),
              const Divider(height: 24),
              const Text('감상', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_entry.content),
            ],
          ],
        ),
      ),
    );
  }
}

/// 기록보기 페이지 (검색 · 정렬 · 즐겨찾기 토글)
class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});
  @override State<DiaryListPage> createState() => _DiaryListPageState();
}

enum SortOrder { dateDesc, dateAsc, titleAsc }

class _DiaryListPageState extends State<DiaryListPage> {
  final box = Hive.box<DiaryEntry>('entries');
  String _search = '';
  bool _favoritesOnly = false;
  SortOrder _order = SortOrder.dateDesc;

  List<DiaryEntry> _applyFilter(Box<DiaryEntry> b) {
    var list = b.values.toList();
    if (_favoritesOnly) list = list.where((e) => e.isFavorite).toList();
    if (_search.isNotEmpty) list = list.where((e) => e.title.contains(_search)).toList();
    list.sort((a, b) {
      switch (_order) {
        case SortOrder.dateAsc:  return a.date.compareTo(b.date);
        case SortOrder.dateDesc: return b.date.compareTo(a.date);
        case SortOrder.titleAsc: return a.title.compareTo(b.title);
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록보기'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '독서 기록 검색',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () async {
                  final sel = await showMenu<SortOrder>(
                    context: context,
                    position: const RelativeRect.fromLTRB(100, 80, 0, 0),
                    items: const [
                      PopupMenuItem(value: SortOrder.dateDesc, child: Text('최신순')),
                      PopupMenuItem(value: SortOrder.dateAsc,  child: Text('오래된순')),
                      PopupMenuItem(value: SortOrder.titleAsc, child: Text('제목순')),
                    ],
                  );
                  if (sel != null) setState(() => _order = sel);
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_favoritesOnly ? Icons.star : Icons.star_border),
                color: Colors.amber,
                onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
              ),
            ]),
          ),
        ),
      ),
      body: ValueListenableBuilder<Box<DiaryEntry>>(
        valueListenable: box.listenable(),
        builder: (context, box, _) {
          final entries = _applyFilter(box);
          if (entries.isEmpty) {
            return const Center(child: Text('아직 기록된 일기가 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const Divider(),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              return ListTile(
                title: Text(e.title),
                subtitle: Text('${e.date.toLocal()}'.split(' ')[0]),
                trailing: e.isFavorite ? const Icon(Icons.star, color: Colors.amber) : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DiaryDetailPage(entry: e)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 홈 화면 (오늘의 일기 · 금주의 독서 시간 · 랜덤 피드백)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<DiaryEntry>('entries');
    final now = DateTime.now();

    // 오늘 일기
    final todayEntries = box.values.where((e) =>
    e.date.year  == now.year &&
        e.date.month == now.month &&
        e.date.day   == now.day
    ).toList();

    // 이번주 통계
    final thisWeek = box.values.where((e) => now.difference(e.date).inDays < 7).toList();
    final totalWeekly = thisWeek.fold<int>(0, (s, e) => s + e.minutes);

    // 지난주 통계
    final lastWeek = box.values.where((e) {
      final d = now.difference(e.date).inDays;
      return d >= 7 && d < 14;
    }).toList();

    // 감상 평균 비교
    final avgThis = thisWeek.isEmpty ? 0 : thisWeek.fold<int>(0, (s, e) => s + e.content.length) ~/ thisWeek.length;
    final avgLast = lastWeek.isEmpty ? 0 : lastWeek.fold<int>(0, (s, e) => s + e.content.length) ~/ lastWeek.length;

    // 3일 연속 기록 여부
    final streak3 = List.generate(3, (i) => now.subtract(Duration(days: i)))
        .every((day) => box.values.any((e) =>
    e.date.year  == day.year &&
        e.date.month == day.month &&
        e.date.day   == day.day
    ));

    // 이번주 고유 기록 일수
    final thisWeekDays = <DateTime>{};
    for (var e in thisWeek) {
      thisWeekDays.add(DateTime(e.date.year, e.date.month, e.date.day));
    }

    // 이번달 통계
    final thisMonth = box.values.where((e) =>
    e.date.year  == now.year &&
        e.date.month == now.month
    ).toList();
    final monthTotal = thisMonth.fold<int>(0, (s, e) => s + e.minutes);
    final monthCount = thisMonth.length;

    // 지난달 비교
    final prevMonth = DateTime(now.year, now.month - 1);
    final lastMonth = box.values.where((e) =>
    e.date.year  == prevMonth.year &&
        e.date.month == prevMonth.month
    ).toList();
    final lastMonthTotal = lastMonth.fold<int>(0, (s, e) => s + e.minutes);
    final monthDiff = monthTotal - lastMonthTotal;

    // 1시간 이상 읽은 날 개수
    final dailySum = <DateTime,int>{};
    for (var e in thisMonth) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      dailySum[d] = (dailySum[d] ?? 0) + e.minutes;
    }
    final days60count = dailySum.values.where((sum) => sum >= 60).length;

    // 피드백 후보
    final candidates = <String>[];
    if (totalWeekly >= 150)        candidates.add("🎉 이번주 독서왕! 총 ${totalWeekly}분을 기록하셨네요!");
    if (totalWeekly >= 300)        candidates.add("🏆 어마어마해요! 이번주 ${totalWeekly}분 읽어내신 독서 챔피언!");
    if (avgThis > avgLast)         candidates.add("✍️ 감상 평균 글자가 ${avgThis}자만큼 늘었어요! 글이 점점 깊어집니다.");
    if (streak3)                   candidates.add("🔥 3일 연속 독서 성공! 꾸준함의 정석을 보여주셨네요.");
    if (thisWeekDays.length >= 5)  candidates.add("💪 이번주 ${thisWeekDays.length}일 이상 기록! 당신의 독서 루틴은 탄탄해요.");
    if (monthTotal >= 600)         candidates.add("🌟 이번달 총 ${monthTotal}분! 한 달 동안 열정적으로 읽으셨군요!");
    if (monthCount >= 8)           candidates.add("📚 이번달 ${monthCount}번 이상의 일기 작성! 독서 습관이 완벽히 자리잡았습니다.");
    if (monthDiff > 0)             candidates.add("📈 지난달보다 ${monthDiff}분 더 읽으셨어요! 성장하는 독서가 멋집니다.");
    if (days60count >= 10)         candidates.add("⏱ ${days60count}일 이상 1시간 독서 달성! 집중력의 달인이세요.");

    final feedback = candidates.isNotEmpty
        ? candidates[Random().nextInt(candidates.length)]
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 오늘의 일기
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('오늘의 일기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (todayEntries.isEmpty)
                  const Text('아직 작성된 일기가 없습니다.')
                else ...[
                  Text(todayEntries.last.title),
                  const SizedBox(height: 4),
                  Text('${todayEntries.last.minutes}분 읽음'),
                ],
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // 금주의 독서 시간
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('금주의 독서 시간', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: totalWeekly / 600),
                const SizedBox(height: 4),
                Text('$totalWeekly 분'),
              ]),
            ),
          ),

          // 동기 부여 피드백
          if (feedback != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(feedback, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// 독서 분석 페이지 (주간 · 월간 그래프)
class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<DiaryEntry>('entries');
    final now = DateTime.now();

    // 주간 집계
    final weekTotals = List<int>.filled(7, 0);
    int lastWeekTotal = 0;
    for (var e in box.values) {
      final diff = now.difference(e.date).inDays;
      if (diff >= 0 && diff < 7) weekTotals[diff] += e.minutes;
      if (diff >= 7 && diff < 14) lastWeekTotal += e.minutes;
    }
    final weekTotal = weekTotals.fold(0, (s, m) => s + m);
    final weekDiff = weekTotal - lastWeekTotal;

    // 월간 집계 (4주)
    final monthBuckets = List<int>.filled(4, 0);
    final lastMonthBuckets = List<int>.filled(4, 0);
    for (var e in box.values) {
      if (e.date.year == now.year && e.date.month == now.month) {
        final w = ((e.date.day - 1) ~/ 7).clamp(0, 3);
        monthBuckets[w] += e.minutes;
      }
      final prev = DateTime(now.year, now.month - 1);
      if (e.date.year == prev.year && e.date.month == prev.month) {
        final w = ((e.date.day - 1) ~/ 7).clamp(0, 3);
        lastMonthBuckets[w] += e.minutes;
      }
    }
    final monthTotal = monthBuckets.fold(0, (s, m) => s + m);
    final lastMonthTotal = lastMonthBuckets.fold(0, (s, m) => s + m);
    final monthDiff = monthTotal - lastMonthTotal;

    const labelsWeek = ['일','월','화','수','목','금','토'];
    const labelsMonth = ['1주','2주','3주','4주'];

    final allValues = [...weekTotals, ...monthBuckets];
    final maxValue = (allValues.isEmpty ? 1 : allValues.reduce(max)).clamp(1, double.infinity);

    Widget buildBar(int minutes, String label) {
      final barHeight = (minutes / maxValue) * 112;
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(width: 16, height: barHeight, color: Colors.indigo),
            const SizedBox(height: 4),
            Text('$minutes분', style: const TextStyle(fontSize: 10)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('독서 분석')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('주간 독서 패턴', style: TextStyle(fontSize:16,fontWeight:FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 200,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(children: List.generate(7, (i) => buildBar(weekTotals[i], labelsWeek[i]))),
          ),
          const SizedBox(height: 4),
          Text('지난주 대비 ${weekDiff >= 0 ? '+' : ''}$weekDiff분',
            style: TextStyle(fontSize:12, color: weekDiff >= 0 ? Colors.green : Colors.red),
          ),

          const SizedBox(height: 24),
          const Text('월간 독서 패턴', style: TextStyle(fontSize:16,fontWeight:FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 200,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(children: List.generate(4, (i) => buildBar(monthBuckets[i], labelsMonth[i]))),
          ),
          const SizedBox(height: 4),
          Text('지난달 대비 ${monthDiff >= 0 ? '+' : ''}$monthDiff분',
            style: TextStyle(fontSize:12, color: monthDiff >= 0 ? Colors.green : Colors.red),
          ),
        ]),
      ),
    );
  }
}

/// 설정 화면 (알림 · 테마 · 글꼴 · 백업)
enum AppTheme { system, light, dark }
enum FontSizeOption { small, normal, large }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _routineNotification = false;
  TimeOfDay _routineTime = const TimeOfDay(hour: 20, minute: 0);
  bool _weeklySummary = false;
  TimeOfDay _summaryTime = const TimeOfDay(hour: 9, minute: 0);
  AppTheme _theme = AppTheme.system;
  FontSizeOption _fontSize = FontSizeOption.normal;

  Future<void> _pickTimeOfDay(TimeOfDay initial, ValueChanged<TimeOfDay> onConfirm) async {
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t != null) onConfirm(t);
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('백업 내보내기(.json) 기능 호출')),
    );
  }

  void _importData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('백업 복원 기능 호출')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('알림 설정', style: TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        SwitchListTile(
          title: const Text('독서 루틴 알림'),
          value: _routineNotification,
          onChanged: (v) => setState(() => _routineNotification = v),
        ),
        if (_routineNotification)
          ListTile(
            title: const Text('알림 시간'),
            subtitle: Text(_routineTime.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () => _pickTimeOfDay(_routineTime, (t) => setState(() => _routineTime = t)),
          ),
        SwitchListTile(
          title: const Text('주간 요약 알림'),
          value: _weeklySummary,
          onChanged: (v) => setState(() => _weeklySummary = v),
        ),
        if (_weeklySummary)
          ListTile(
            title: const Text('알림 요일/시간'),
            subtitle: Text(_summaryTime.format(context)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickTimeOfDay(_summaryTime, (t) => setState(() => _summaryTime = t)),
          ),

        const Divider(height: 32),
        const Text('테마 / 글꼴 크기', style: TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        RadioListTile<AppTheme>(
          title: const Text('시스템 테마'),
          value: AppTheme.system,
          groupValue: _theme,
          onChanged: (v) => setState(() => _theme = v!),
        ),
        RadioListTile<AppTheme>(
          title: const Text('라이트 모드'),
          value: AppTheme.light,
          groupValue: _theme,
          onChanged: (v) => setState(() => _theme = v!),
        ),
        RadioListTile<AppTheme>(
          title: const Text('다크 모드'),
          value: AppTheme.dark,
          groupValue: _theme,
          onChanged: (v) => setState(() => _theme = v!),
        ),

        const SizedBox(height: 16),
        const Text('본문 글꼴 크기'),
        RadioListTile<FontSizeOption>(
          title: const Text('작게'),
          value: FontSizeOption.small,
          groupValue: _fontSize,
          onChanged: (v) => setState(() => _fontSize = v!),
        ),
        RadioListTile<FontSizeOption>(
          title: const Text('보통'),
          value: FontSizeOption.normal,
          groupValue: _fontSize,
          onChanged: (v) => setState(() => _fontSize = v!),
        ),
        RadioListTile<FontSizeOption>(
          title: const Text('크게'),
          value: FontSizeOption.large,
          groupValue: _fontSize,
          onChanged: (v) => setState(() => _fontSize = v!),
        ),

        const Divider(height: 32),
        const Text('데이터 관리', style: TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _exportData,
          icon: const Icon(Icons.upload_file),
          label: const Text('로컬 백업 내보내기 (.json)'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _importData,
          icon: const Icon(Icons.download),
          label: const Text('백업 파일에서 복원'),
        ),
      ]),
    );
  }
}

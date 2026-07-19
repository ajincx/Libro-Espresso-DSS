import 'dart:io';

void main() {
  final file = File('lib/screens/login_screen.dart');
  var lines = file.readAsLinesSync();
  
  // Find where it got mangled
  int idx = lines.indexWhere((l) => l.contains('builder: (_) => const DashboardScreen(),'));
  if (idx != -1) {
    int nextIdx = lines.indexWhere((l) => l.contains('children: ['), idx);
    if (nextIdx != -1) {
      lines.removeRange(idx + 1, nextIdx);
      lines.insertAll(idx + 1, [
        '        ),',
        '      );',
        '    } catch (e) {',
        '      _showError(e.toString().replaceAll(\'Exception: \', \'\'));',
        '    } finally {',
        '      if (mounted) setState(() => _isLoading = false);',
        '    }',
        '  }',
        '',
        '  void _showError(String message) {',
        '    ScaffoldMessenger.of(context).showSnackBar(',
        '      SnackBar(',
        '        content: Text(message, style: const TextStyle(color: Colors.white, fontFamily: \'Poppins\')),',
        '        backgroundColor: Colors.redAccent,',
        '        behavior: SnackBarBehavior.floating,',
        '        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),',
        '      ),',
        '    );',
        '  }',
        '',
        '  @override',
        '  Widget build(BuildContext context) {',
        '    return Scaffold(',
        '      body: GestureDetector(',
        '        onTap: () => FocusScope.of(context).unfocus(),',
        '        behavior: HitTestBehavior.translucent,',
        '        child: MouseRegion(',
        '          child: Stack(',
        '            children: [',
        '              // ULTRA PREMIUM LAYERED BACKGROUND',
        '              const _UltraPremiumBackground(),',
        '              ',
        '              // MAIN CONTENT WRAPPER',
        '              SafeArea(',
        '                child: LayoutBuilder(',
        '                  builder: (context, constraints) {',
        '                    return SingleChildScrollView(',
        '                      child: ConstrainedBox(',
        '                        constraints: BoxConstraints(',
        '                          minHeight: constraints.maxHeight,',
        '                        ),',
        '                        child: Center(',
        '                          child: Padding(',
        '                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),',
        '                            child: ConstrainedBox(',
        '                              constraints: const BoxConstraints(maxWidth: 360),',
        '                              child: Column(',
        '                                mainAxisAlignment: MainAxisAlignment.center,'
      ]);
    }
  }
  
  file.writeAsStringSync(lines.join('\n'));
  print('Done');
}

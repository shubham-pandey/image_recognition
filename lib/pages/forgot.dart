import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  bool _loading = false;

Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _loading = false);
    // On success navigate to home: Navigator.pushReplacementNamed(context, '/');
  }
  @override
  Widget build(BuildContext context) {
    final bg = LinearGradient(
      colors: [const Color.fromARGB(255, 201, 201, 201), const Color.fromARGB(255, 69, 69, 69)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        leading: BackButton(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: bg),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                color: Colors.grey.shade50,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(height: 12),
                    const Text('Forgot Password?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    Text('No worries, It happens! Just enter the email address', style: TextStyle(color: Colors.grey.shade600),),
                    const SizedBox(height: 50),
                    TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email required';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 30,),
                    SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade900,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                            ),
                            child: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Send Code', style: TextStyle(fontSize: 16), ),
                          ),
                        ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
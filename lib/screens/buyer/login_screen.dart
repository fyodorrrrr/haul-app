import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haul/screens/buyer/forgot_password_screen.dart';
import 'package:haul/screens/buyer/register_screen.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '/widgets/loading_screen.dart';
import '/theme/app_theme.dart';
import 'register_info_screen.dart';
import '../seller/seller_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _obscurePassword = true;

  // Helper to check if user is a seller
  Future<bool> _checkSellerStatus(String uid) async {
    try {
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(uid)
          .get();
      return sellerDoc.exists;
    } catch (e) {
      print('Error checking seller status: $e');
      return false;
    }
  }

  //LOGIC FOR LOGIN 
  Future<void> signInUser() async {
    LoadingScreen.show(context); // Show loading screen
    if (_formKey.currentState!.validate()) {
      try {
        // Step 1: Sign in with Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Step 2: Get UID of the logged in user
        String uid = userCredential.user!.uid;

        // Step 3: Check if user is a seller
        bool isSeller = await _checkSellerStatus(uid);

        // Step 4: Fetch additional info from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          LoadingScreen.hide(context); // Hide loading screen on error
          final userData = userDoc.data() as Map<String, dynamic>;

          // Debug print (optional)
          print("User Info from Firestore: $userData");

          // Step 5: Navigate based on seller status and saved preference
          bool prefersSeller = userData['prefersSeller'] == true;

          if (isSeller && prefersSeller) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SellerDashboardScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen(userData: userData)),
            );
          }
        } else {
          // Create a basic user document if it doesn't exist
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'email': _emailController.text.trim(),
            'role': 'buyer',
            'created_at': FieldValue.serverTimestamp(),
          });

          LoadingScreen.hide(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(userData: {
              'uid': uid,
              'email': _emailController.text.trim(),
              'role': 'buyer',
            })),
          );
        }
      } catch (e) {
        LoadingScreen.hide(context); // Hide loading screen on error
        if (e.toString().contains('permission-denied')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(
              'Permission issue. Please check that you have the right access.',
              style: TextStyle(color: Colors.white),
            ), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${e.toString()}')),
          );
        }
      }
    } else {
      LoadingScreen.hide(context);
    }
  }

  // Google Sign-In
  Future<void> _signInWithGoogle() async {
    try {
      LoadingScreen.show(context);
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
        forceCodeForRefreshToken: true,
      ).signIn().catchError((error) {
        print("Error in GoogleSignIn.signIn(): $error");
        throw error;
      });
      if (googleUser == null) {
        LoadingScreen.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In was canceled')),
        );
        return;
      }
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid);
      try {
        final userDoc = await userRef.get();
        LoadingScreen.hide(context);
        Map<String, dynamic> userData;
        if (!userDoc.exists) {
          userData = {
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'fullName': userCredential.user!.displayName,
            'photoUrl': userCredential.user!.photoURL,
            'role': 'buyer',
            'created_at': FieldValue.serverTimestamp(),
            'provider': 'google',
          };
          await userRef.set(userData);
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            // Check if user is a seller
            bool isSeller = await _checkSellerStatus(userCredential.user!.uid);
            userData['isSeller'] = isSeller;
            if (isSeller && (userData['prefersSeller'] == true)) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const SellerDashboardScreen(),
                ),
                (route) => false,
              );
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => RegisterInfoScreen(userData: userData),
                ),
                (route) => false,
              );
            }
          });
        } else {
          userData = userDoc.data() as Map<String, dynamic>;
          // Check if user is a seller
          bool isSeller = await _checkSellerStatus(userCredential.user!.uid);
          userData['isSeller'] = isSeller;
          if (isSeller && (userData['prefersSeller'] == true)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const SellerDashboardScreen(),
                ),
                (route) => false,
              );
            });
          } else if (userData['phone'] == null || userData['gender'] == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => RegisterInfoScreen(userData: userData),
                ),
                (route) => false,
              );
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => HomeScreen(userData: userData),
                ),
                (route) => false,
              );
            });
          }
        }
      } catch (firestoreError) {
        LoadingScreen.hide(context);
        print("Firestore error: $firestoreError");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database error: ${_getFriendlyError(firestoreError)}'))
        );
      }
    } catch (e) {
      LoadingScreen.hide(context);
      print("Google sign-in process error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${_getFriendlyError(e)}'), 
        backgroundColor: AppTheme.errorColor)
      );
    }
  }

  // Example: Seller mode toggle for use in a drawer or menu
  static Future<void> switchToSellerMode(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final loginScreenState = context.findAncestorStateOfType<_LoginScreenState>();
    if (loginScreenState == null) return;
    bool isSeller = await loginScreenState._checkSellerStatus(uid);
    if (isSeller) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'prefersSeller': true});
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerDashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not registered as a seller.')),
      );
    }
  }

  String _getFriendlyError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'wrong-password':
          return 'Incorrect password';
        case 'user-not-found':
          return 'No account found with this email';
        case 'account-exists-with-different-credential':
          return 'This email is already linked with another sign-in method';
        case 'network-request-failed':
          return 'Network error. Please check your connection';
        default:
          return error.message ?? 'Sign-in failed';
      }
    }
    return error.toString();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 350;

    return Scaffold(
      backgroundColor: Colors.white,
      // Remove app bar for cleaner look
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: size.height * 0.05, // Add more top padding
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and Tagline - Make more compact
                Center(
                  child: Column(
                    children: [
                      // Smaller Logo Image
                      Image.asset(
                        'assets/haul_logo.png',
                        height: size.height * 0.4, // Reduced from 0.4
                      ),
                      Transform.translate(
                        offset: Offset(0, -20), // Adjust the offset as needed
                        child :Text(
                        "Let's thrift together",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                         ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.002),

                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field - updated style
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // Password Field - updated style
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade700,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot your Password?',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Sign In Button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      signInUser();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),

                // OR divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "OR",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                ),

                // Google Sign In Button
                OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Image.asset(
                    'assets/google_logo.png', // You'll need to add this asset
                    height: 20,
                    width: 20,
                  ),
                  label: Text(
                    'Sign in with Google',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Create Account Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Create an account',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
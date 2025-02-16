import 'package:flutter/material.dart';
import 'package:my_app/screens/signInScreens/counsellor_signup_data.dart';
import 'package:my_app/services/auth_service.dart';
import 'counsellor_sucess_signup.dart';

class CounsellorSignUpStepper extends StatefulWidget {
  @override
  _CounsellorSignUpStepperState createState() =>
      _CounsellorSignUpStepperState();
}

class _CounsellorSignUpStepperState extends State<CounsellorSignUpStepper> {
  int _currentStep = 0;
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Ensure it's initialized
  CounsellorSignUpData signUpData = CounsellorSignUpData();
  bool isPasswordVisible = false;
  List<String> selectedExpertise = [];
  String? selectedState;
  PageController _pageController = PageController();

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        _pageController.animateToPage(
          _currentStep,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _pageController.animateToPage(
          _currentStep,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _submitSignUp() async {
    try {
      print("Sign Up function started!");

      if (_formKey.currentState == null) {
        print("Error: Form key is null before validation!");
        throw Exception("Form key is not initialized properly.");
      }

      if (!_formKey.currentState!.validate()) {
        print("Validation failed.");
        throw Exception(
            "Please fill in all required fields before submitting.");
      }

      _formKey.currentState!.save();
      signUpData.expertise = selectedExpertise;
      signUpData.stateOfCounsellor = selectedState;

      print("First Name: ${signUpData.firstName}");
      print("Last Name: ${signUpData.lastName}");
      print("Phone Number: ${signUpData.phoneNumber}");
      print("Email: ${signUpData.email}");
      print("Password: ${signUpData.password}");
      print("Rate Per Year: ${signUpData.ratePerYear}");
      print("Expertise: ${signUpData.expertise}");
      print("State: ${signUpData.stateOfCounsellor}");

      if (signUpData.stateOfCounsellor == null ||
          signUpData.stateOfCounsellor!.isEmpty) {
        print("Error: State is null or empty.");
        throw Exception("Please select a state before submitting.");
      }

      if (signUpData.expertise.isEmpty) {
        print("Error: Expertise list is empty.");
        throw Exception(
            "Please select at least one expertise before submitting.");
      }

      double ratePerYear = signUpData.ratePerYear ?? 0.0;
      print("Final Rate Per Year: $ratePerYear");

      print("Sending API request...");
      String? result = await AuthService.counsellorSignUp(
        signUpData.firstName ?? "",
        signUpData.lastName ?? "",
        signUpData.phoneNumber ?? "",
        signUpData.email ?? "",
        signUpData.password ?? "",
        ratePerYear,
        signUpData.expertise.isNotEmpty ? signUpData.expertise : [""],
        signUpData.stateOfCounsellor ?? "",
      );

      if (result == null || result.isEmpty) {
        print("Error: Received null or empty response from server.");
        throw Exception(
            "Sign Up Failed: Received null or empty response from server.");
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignUpSuccessPage()),
      );
    } catch (e) {
      print("Sign Up Failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign Up Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Counsellor Sign Up"),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey, // Assigning the form key at the parent level
        child: Column(
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(color: Colors.white),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.white, // Background behind Stepper
                      shadowColor: Colors.transparent,
                      cardColor: Colors.white, // Stepper card color
                    ),
                    child: Stepper(
                      type: StepperType.horizontal,
                      currentStep: _currentStep,
                      onStepContinue: _nextStep,
                      onStepCancel: _previousStep,
                      steps: [
                        Step(
                            title: Text("Basic"),
                            content: SizedBox.shrink(),
                            isActive: _currentStep >= 0),
                        Step(
                            title: Text("Expertise"),
                            content: SizedBox.shrink(),
                            isActive: _currentStep >= 1),
                        Step(
                            title: Text("State"),
                            content: SizedBox.shrink(),
                            isActive: _currentStep >= 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              _buildTextField(
                  "First Name", (value) => signUpData.firstName = value),
              _buildTextField(
                  "Last Name", (value) => signUpData.lastName = value),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.grey.shade400, width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.orangeAccent, width: 1),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/indian_flag.png',
                              width: 24),
                          SizedBox(width: 6),
                          Text("+91",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    if (!value.startsWith("+91")) {
                      signUpData.phoneNumber = "+91" + value;
                    } else {
                      signUpData.phoneNumber = value;
                    }
                  },
                ),
              ),
              _buildTextField("Email", (value) => signUpData.email = value,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField(
                  "Password", (value) => signUpData.password = value,
                  obscureText: true),
              _buildTextField("Rate per Year",
                  (value) => signUpData.ratePerYear = double.tryParse(value)),
              SizedBox(height: 20),
              _buildNextButton(_nextStep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    List<String> expertiseOptions = [
      "HSC",
      "ENGINEERING",
      "MEDICAL",
      "MBA",
      "OTHERS"
    ];
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Let's know your expertise",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: expertiseOptions.map((exp) {
                bool isSelected = selectedExpertise.contains(exp);
                return ChoiceChip(
                  checkmarkColor: Colors.orangeAccent,
                  label: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(exp,
                        style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? Colors.grey.shade600
                                : Colors.grey.shade600)),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.white,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      isSelected
                          ? selectedExpertise.remove(exp)
                          : selectedExpertise.add(exp);
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            _buildNextButton(_nextStep),
            SizedBox(height: 20),
            _buildBackButton(_previousStep)
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    List<Map<String, String>> states = [
      {"name": "KARNATAKA", "image": "assets/images/kar.png"},
      {"name": "MAHARASHTRA", "image": "assets/images/maha.png"},
      {"name": "TAMILNADU", "image": "assets/images/tamil.png"},
      {"name": "OTHERS", "image": "assets/images/indian.png"},
    ];
    return Column(
      children: [
        Text("Select State",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600)),
        SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: states.map((state) {
            bool isSelected = selectedState == state["name"];
            return GestureDetector(
              onTap: () {
                setState(() => selectedState = state["name"]);
              },
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        state["image"]!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Divider(
                      color: isSelected
                          ? Colors.orange.shade300
                          : Colors.grey.shade300,
                      thickness: 2,
                      indent: 10,
                      endIndent: 10),
                  SizedBox(height: 6),
                  Text(
                    state["name"]!,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.orange.shade400
                            : Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: EdgeInsets.all(14),
                shape: CircleBorder(),
              ),
              onPressed: _previousStep,
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.all(14),
                shape: CircleBorder(),
              ),
              onPressed: _submitSignUp,
              child: Icon(Icons.check, color: Colors.white),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, Function(String) onSave,
      {TextInputType keyboardType = TextInputType.text,
      bool obscureText = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.orangeAccent, width: 1),
          ),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onSave,
        validator: (value) =>
            value == null || value.isEmpty ? "This field is required" : null,
      ),
    );
  }

  Widget _buildNextButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          padding: EdgeInsets.all(14),
          shape: CircleBorder(),
        ),
        onPressed: onPressed,
        child: Icon(
          Icons.arrow_forward,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildBackButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          padding: EdgeInsets.all(14),
          shape: CircleBorder(),
        ),
        onPressed: onPressed,
        child: Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

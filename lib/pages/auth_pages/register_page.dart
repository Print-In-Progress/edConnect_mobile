import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/providers/modulesprovider.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/models/registration_fields.dart';
import 'package:edconnect_mobile/services/auth_service.dart';
import 'package:edconnect_mobile/services/data_services.dart';
import 'package:edconnect_mobile/utils/card_builders/registration_card_builder.dart';
import 'package:edconnect_mobile/widgets/buttons.dart';
import 'package:edconnect_mobile/widgets/forms.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:edconnect_mobile/widgets/terms_and_conditions_checkbox.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late Future<List<BaseRegistrationField>> _futureDocs;
  // text controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmedPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isCheckedAgreement = false;

  bool _validateFirstNameField = false;
  bool _validateLastNameField = false;
  bool _validateEmailField = false;

  bool _isDataFetched = false;

  final AuthService _authService = AuthService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      _futureDocs = DataService().fetchRegistrationFieldData(
          Provider.of<DatabaseCollectionProvider>(context));
      _isDataFetched = true;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> signUp(BuildContext context) async {
    final email = _emailController.text;
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final password = _passwordController.text;
    final confirmedPassword = _confirmedPasswordController.text;
    final databaseProvider =
        Provider.of<DatabaseCollectionProvider>(context, listen: false);
    final colorAndLogoProvider =
        Provider.of<ColorANDLogoProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    final modulesProvider =
        Provider.of<UserModulesProvider>(context, listen: false);
    try {
      List<BaseRegistrationField> registrationFields = await _futureDocs;
      String? result = await _authService.signUp(
        email,
        firstName,
        lastName,
        password,
        confirmedPassword,
        registrationFields,
        databaseProvider,
        modulesProvider,
        colorAndLogoProvider,
      );

      if (result != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleSignUpResult(
              result, localizations, registrationFields, context);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          successMessage(
            context,
            AppLocalizations.of(context)!.authPagesRegisterSuccessSnackbarLabel,
          );
        });
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        errorMessage(context, e.toString());
      });
    }
  }

  void handleSignUpResult(String result, AppLocalizations localizations,
      List<BaseRegistrationField> registrationFields, BuildContext context) {
    switch (result) {
      case 'PasswordsDoNotMatch':
        errorMessage(
            context, localizations.authPagesConfirmPasswordErrorSnackbarLabel);
        break;
      case 'EmailAlreadyInUse':
        errorMessage(
            context, localizations.firebaseAuthErrorMessageEmailAlreadyInUse);
        break;
      case 'AccountAlreadyExistsWithOtherOrg':
        handleAccountAlreadyExistsWithOtherOrg(
            registrationFields, context, localizations);
        break;
      case 'SignatureMissing':
        errorMessage(
            context, AppLocalizations.of(context)!.authPagesSignatureMissing);
        break;
      case 'QuestionMissing':
        errorMessage(
          context,
          AppLocalizations.of(context)!.authPagesFieldMissing,
        );
        break;
      default:
        errorMessage(context,
            '${AppLocalizations.of(context)!.globalUnexpectedErrorLabel}: ${result.split(' ').last}');
    }
  }

  void handleAccountAlreadyExistsWithOtherOrg(
      List<BaseRegistrationField> registrationFields,
      BuildContext context,
      AppLocalizations localizations) async {
    final email = _emailController.text;
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final password = _passwordController.text;
    final confirmedPassword = _confirmedPasswordController.text;
    final databaseProvider =
        Provider.of<DatabaseCollectionProvider>(context, listen: false);
    final colorAndLogoProvider =
        Provider.of<ColorANDLogoProvider>(context, listen: false);
    final modulesProvider =
        Provider.of<UserModulesProvider>(context, listen: false);

    try {
      String? result = await _authService.signUpToOrg(
        email,
        firstName,
        lastName,
        password,
        confirmedPassword,
        registrationFields,
        databaseProvider,
        modulesProvider,
        colorAndLogoProvider,
      );

      if (result != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          errorMessage(context,
              '${localizations.globalUnexpectedErrorLabel}: ${result.split(' ').last}');
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          successMessage(
            context,
            AppLocalizations.of(context)!.authPagesRegisterSuccessSnackbarLabel,
          );
        });
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        errorMessage(context, e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(int.parse(currentColorSchemeProvider.primaryColor)),
                Color(int.parse(currentColorSchemeProvider.secondaryColor))
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width < 700
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width / 2,
                  child: Card(
                    elevation: 50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Customer Logo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                  child: FractionallySizedBox(
                                      widthFactor: 0.7,
                                      child: currentColorSchemeProvider
                                                  .logoLink !=
                                              ''
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  currentColorSchemeProvider
                                                      .logoLink,
                                              progressIndicatorBuilder:
                                                  (context, url,
                                                          downloadProgress) =>
                                                      Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        value: downloadProgress
                                                            .progress),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Center(
                                                child: Text(AppLocalizations.of(
                                                        context)!
                                                    .globalImgCouldNotBeFound),
                                              ),
                                            )
                                          : Image.asset(
                                              'assets/NewsApp_Logo_Mobilexxhdpi.png'))),
                              Flexible(
                                  child: FractionallySizedBox(
                                widthFactor: 0.7,
                                child: themeChangeProvider.darkTheme
                                    ? Image.asset(
                                        'assets/pip_branding_dark_mode_verticalxxxhdpi.png')
                                    : Image.asset(
                                        'assets/pip_branding_light_mode_verticalxxxhdpi.png'),
                              ))
                            ],
                          ),

                          // Greeting
                          Text(
                            AppLocalizations.of(context)!
                                .authPagesWelcomeLabelOne,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 32),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            AppLocalizations.of(context)!
                                .authPagesRegisterWelcomeLabelTwo,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(
                            height: 20,
                          ),

                          PIPOutlinedBorderInputForm(
                            validate: _validateFirstNameField,
                            width: MediaQuery.of(context).size.width,
                            controller: _firstNameController,
                            label: AppLocalizations.of(context)!
                                .globalFirstNameTextFieldHintText,
                            icon: Icons.person,
                          ),
                          const SizedBox(
                            height: 5,
                          ),

                          PIPOutlinedBorderInputForm(
                            validate: _validateLastNameField,
                            width: MediaQuery.of(context).size.width,
                            controller: _lastNameController,
                            label: AppLocalizations.of(context)!
                                .globalLastNameTextFieldHintText,
                            icon: Icons.person,
                          ),
                          const SizedBox(
                            height: 5,
                          ),

                          PIPOutlinedBorderInputForm(
                            validate: _validateEmailField,
                            width: MediaQuery.of(context).size.width,
                            controller: _emailController,
                            label:
                                AppLocalizations.of(context)!.globalEmailLabel,
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          PIPPasswordForm(
                              label: AppLocalizations.of(context)!
                                  .globalPasswordLabel,
                              width: MediaQuery.of(context).size.width,
                              controller: _passwordController,
                              passwordVisible: _passwordVisible,
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              }),
                          const SizedBox(
                            height: 5,
                          ),

                          PIPPasswordForm(
                              label: AppLocalizations.of(context)!
                                  .authPagesRegisterConfirmPasswordTextFieldHintText,
                              width: MediaQuery.of(context).size.width,
                              controller: _confirmedPasswordController,
                              passwordVisible: _confirmPasswordVisible,
                              onPressed: () {
                                setState(() {
                                  _confirmPasswordVisible =
                                      !_confirmPasswordVisible;
                                });
                              }),

                          TermsAndConditionsCheckbox(
                            isChecked: _isCheckedAgreement,
                            onChanged: (value) {
                              setState(() {
                                _isCheckedAgreement = value;
                              });
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),

                          FutureBuilder<List<BaseRegistrationField>>(
                              future: _futureDocs,
                              builder: ((context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Column(
                                    children: List.generate(
                                      5,
                                      (index) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2.5),
                                        child: Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  height: 20.0,
                                                  color: Colors.grey[300],
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  width: double.infinity,
                                                  height: 20.0,
                                                  color: Colors.grey[300],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else if (snapshot.hasData) {
                                  return ListView.builder(
                                      itemBuilder: (context, index) {
                                        return buildRegistrationCard(
                                            context, snapshot.data!, index);
                                      },
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: snapshot.data!.length);
                                } else {
                                  return const SizedBox.shrink();
                                }
                              })),
                          const SizedBox(
                            height: 10,
                          ),
                          PIPResponsiveRaisedButton(
                            label: AppLocalizations.of(context)!
                                .authPagesRegisterButtonLabel,
                            onPressed: () {
                              setState(() {
                                _firstNameController.text.isEmpty
                                    ? _validateFirstNameField = true
                                    : _validateFirstNameField = false;
                                _lastNameController.text.isEmpty
                                    ? _validateLastNameField = true
                                    : _validateLastNameField = false;
                                _emailController.text.isEmpty
                                    ? _validateEmailField = true
                                    : _validateEmailField = false;
                              });
                              if (_isCheckedAgreement &&
                                  _firstNameController.text.isNotEmpty &&
                                  _lastNameController.text.isNotEmpty &&
                                  _emailController.text.isNotEmpty) {
                                signUp(context);
                              } else if (!_isCheckedAgreement) {
                                errorMessage(
                                    context,
                                    durationMilliseconds: 10000,
                                    AppLocalizations.of(context)!
                                        .authPagesRegisterAcceptToSAndPrivacyPolicyErrorMessage);
                              } else if (_firstNameController.text.isEmpty ||
                                  _lastNameController.text.isEmpty ||
                                  _emailController.text.isEmpty) {
                                errorMessage(
                                  context,
                                  AppLocalizations.of(context)!
                                      .authPagesFieldMissing,
                                  durationMilliseconds: 10000,
                                );
                              }
                            },
                            fontWeight: FontWeight.w700,
                            width: MediaQuery.of(context).size.width < 700
                                ? MediaQuery.of(context).size.width / 2
                                : MediaQuery.of(context).size.width / 4,
                          ),
                          const SizedBox(height: 10),

                          PIPResponsiveTextButton(
                            label: AppLocalizations.of(context)!
                                .authPagesLoginButtonLabel,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w700,
                            onPressed: widget.showLoginPage,
                            width: MediaQuery.of(context).size.width < 700
                                ? MediaQuery.of(context).size.width / 2
                                : MediaQuery.of(context).size.width / 4,
                            height: MediaQuery.of(context).size.height / 20,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}

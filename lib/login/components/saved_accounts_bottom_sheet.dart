import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/models/biometric_credential.dart';
import 'package:zmall/services/biometric_services/biometric_credentials_manager.dart';
import 'package:zmall/services/biometric_services/biometric_service.dart';
import 'package:zmall/utils/size_config.dart';

/// Bottom sheet to show saved accounts
class SavedAccountsBottomSheet extends StatefulWidget {
  final Function(BiometricCredential) onAccountSelected;
  final String? currentUserPhone;

  const SavedAccountsBottomSheet({
    super.key,
    required this.onAccountSelected,
    this.currentUserPhone,
  });

  @override
  State<SavedAccountsBottomSheet> createState() =>
      _SavedAccountsBottomSheetState();
}

class _SavedAccountsBottomSheetState extends State<SavedAccountsBottomSheet> {
  List<BiometricCredential> _accounts = [];
  bool _isLoading = true;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadBiometricType();
  }

  Future<void> _loadAccounts() async {
    final accounts = await BiometricCredentialsManager.getSavedAccounts();
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBiometricType() async {
    final biometricName = await BiometricService.getBiometricTypeName();
    if (mounted) {
      setState(() {
        _biometricType = biometricName;
      });
    }
  }

  Future<void> _deleteAccount(BiometricCredential account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kPrimaryColor,
        title: Text('Remove Account?'),
        content: Text(
          'Remove ${account.displayName} from saved accounts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: kBlackColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(
                color: kSecondaryColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BiometricCredentialsManager.removeAccount(account.phone);
      await _loadAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding),
        vertical: getProportionateScreenHeight(kDefaultPadding / 2),
      ),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kDefaultPadding),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: getProportionateScreenHeight(kDefaultPadding / 2),
        children: [
          // Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(HeroiconsOutline.userCircle),
              SizedBox(width: kDefaultPadding),
              Text(
                'Saved Accounts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              InkWell(
                child: Icon(HeroiconsOutline.xCircle, color: kGreyColor),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),

          // Accounts list
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(kDefaultPadding * 2),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kSecondaryColor),
              ),
            )
          else if (_accounts.isEmpty)
            Padding(
              padding: EdgeInsets.all(kDefaultPadding * 2),
              child: Column(
                children: [
                  Icon(
                    HeroiconsOutline.userCircle,
                    size: 48,
                    color: kGreyColor,
                  ),
                  SizedBox(height: kDefaultPadding),
                  Text(
                    'No saved accounts',
                    style: TextStyle(color: kGreyColor),
                  ),
                ],
              ),
            )
          else
            SafeArea(
              child: ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
                  // vertical: getProportionateScreenHeight(kDefaultPadding / 2),
                ),
                itemCount: _accounts.length,
                separatorBuilder: (context, index) => SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 2)),
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  final isCurrentAccount = widget.currentUserPhone != null &&
                      account.phone == widget.currentUserPhone;

                  return Container(
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      border: Border.all(
                        color: kWhiteColor,
                      ),
                      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: getProportionateScreenHeight(1),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: kSecondaryColor.withValues(alpha: 0.1),
                        child: Text(
                          account.displayName[0].toUpperCase(),
                          style: TextStyle(
                            color: kSecondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        account.displayName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: !isCurrentAccount
                          ? null
                          : Text(
                              'Current',
                              style: TextStyle(
                                color: kSecondaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      // Text(
                      //   account.biometricEnabled
                      //       ? '$_biometricType enabled'
                      //       : 'No biometric',
                      //   style: TextStyle(
                      //     color: account.biometricEnabled
                      //         ? kGreenColor
                      //         : kGreyColor,
                      //     fontSize: 12,
                      //   ),
                      // ),
                      // if (account.biometricEnabled)
                      // Icon(
                      //   Icons.fingerprint,
                      //   color: kSecondaryColor,
                      //   size: 20,
                      // ),
                      trailing: IconButton(
                        icon: Icon(
                          HeroiconsOutline.trash,
                          color: kSecondaryColor,
                          size: 20,
                        ),
                        onPressed: () => _deleteAccount(account),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (!isCurrentAccount) {
                          widget.onAccountSelected(account);
                        } else {
                          Service.showMessage(
                              context: context,
                              title:
                                  "You are already logged in with this account.");
                        }
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Show saved accounts bottom sheet
Future<void> showSavedAccountsBottomSheet({
  required BuildContext context,
  required Function(BiometricCredential) onAccountSelected,
  String? currentUserPhone,
}) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: kPrimaryColor,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SavedAccountsBottomSheet(
      onAccountSelected: onAccountSelected,
      currentUserPhone: currentUserPhone,
    ),
  );
}

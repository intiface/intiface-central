import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:sentry/sentry_io.dart';

class SendLogsPage extends StatelessWidget {
  const SendLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    var contactController = TextEditingController();
    var textController = TextEditingController();
    return Expanded(
        child: Card(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const Text(
              "Send Logs to Developers",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please add your contact info (via email, discord, telegram, x/twitter, bluesky, masto, etc... SUBMISSIONS WITHOUT CONTACT INFO WILL BE IGNORED.) and any information you'd like the devs to know about your issue. Intiface Central logs and config files will be attached automatically.",
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2), borderRadius: BorderRadius.circular(3)),
              child: TextField(
                controller: contactController,
                minLines: 1,
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
                decoration: const InputDecoration(
                    border: InputBorder.none, enabledBorder: InputBorder.none, hintText: "Put contact info here"),
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2), borderRadius: BorderRadius.circular(3)),
              child: TextField(
                controller: textController,
                minLines: 2,
                maxLines: null,
                style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
                decoration: const InputDecoration(
                    border: InputBorder.none, enabledBorder: InputBorder.none, hintText: "Put issue report here"),
              ),
            )),
            SizedBox(
                width: double.infinity,
                child: TextButton(
                    child: const Text("Send Logs..."),
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        barrierDismissible: false, // user must tap button!
                        builder: (BuildContext context) {
                          var contentText = "Sending logs...";
                          var sendFinished = false;
                          var sendFailed = false;
                          // We're going to assume the stateful builder runs before we get a return from our capture.
                          // Bold, possibly stupid move.
                          late StateSetter _setState;
                          Sentry.captureMessage("""Contact Info: ${contactController.value.text}

Message:

${textController.value.text}""", withScope: (scope) {
                            scope.setTag("ManualLogSubmit", true.toString());
                          }).then((value) {
                            _setState(() {
                              contentText = "Logs sent!";
                              sendFinished = true;
                            });
                          }).onError((error, stackTrace) {
                            contentText = "Error sending logs, please try again.";
                            sendFinished = true;
                            sendFailed = true;
                          });

                          return StatefulBuilder(builder: (context, setState) {
                            _setState = setState;
                            return AlertDialog(
                              //title: const Text('Sending Logs'),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    Text(contentText),
                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                    onPressed: sendFinished
                                        ? () {
                                            Navigator.of(context).pop();
                                            if (!sendFailed) {
                                              BlocProvider.of<NavigationCubit>(context).goSettings();
                                            }
                                          }
                                        : null,
                                    child: const Text('Ok'))
                              ],
                            );
                          });
                        },
                      );
                    })),
          ],
        ),
      ),
    ));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:sentry/sentry_io.dart';

class SendLogsPage extends StatelessWidget {
  const SendLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 3), borderRadius: BorderRadius.circular(5)),
              child: TextField(
                controller: textController,
                minLines: 2,
                maxLines: null,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    hintMaxLines: 3,
                    hintText:
                        "Please add your contact info (via email, discord, telegram, x/twitter, bluesky, masto, etc...) and any information you'd like the devs to know about your issue. Intiface Central logs and config files will be attached automatically."),
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
                          Sentry.captureMessage(textController.value.text, withScope: (scope) {
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

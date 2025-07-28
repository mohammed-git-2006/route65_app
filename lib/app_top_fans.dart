import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:route65/no_internet.dart';

class TopFansElement {
  late String name, img;
  late int score;

  TopFansElement({required this.name, required this.score, required this.img});
}

class APIResult {
  late bool ok;
  List<TopFansElement>? result;

  APIResult({required this.ok, this.result});
}

class TopFansAPI {
  static final Uri URL = Uri.parse('https://www.route-65-dashboard.com/api/app-topfans');

  static Future<APIResult> fetch() async {
    try {
      /*
       * The data fetched from the server in json format should look like this : 
       * [
       *  {name: string, score: int, img: string} // Top user
       *  {name: string, score: int, img: string} // 2nd Top user
       * ] 
       */
      final serverResponse = await http.get(TopFansAPI.URL);
      if (serverResponse.statusCode != 200) throw 'Not 200';
      
      final List<dynamic> data = jsonDecode(serverResponse.body);
      final List<TopFansElement> decodedResult = [];

      for(final element in data) {
        decodedResult.add(TopFansElement(
          name: element['name']?.toString() ?? '',
          score: int.tryParse(element['score'].toString()) ?? 0,
          img: element['img']?.toString() ?? '',
        ));
      }

      return APIResult(ok: true, result: decodedResult);
    } catch (err) {
      return APIResult(ok: false);
    }
    
  }
}


class AppTopFans extends StatefulWidget {
  const AppTopFans({super.key});

  @override
  State<AppTopFans> createState() => _AppTopFansState();
}

class _AppTopFansState extends State<AppTopFans> {
  bool loading = true, connectionError = false;
  List<TopFansElement> result = [];

  void loadData() {
    setState(() {
      loading = true;
      connectionError = false;
    });
    TopFansAPI.fetch().then((fetchResult) {
      loading = false;
      connectionError = !fetchResult.ok;
      if (!connectionError && fetchResult.result != null) {
        print('==> Fetch result ==> ${fetchResult.result?.length}');
        result = fetchResult.result!;
      }

      setState(() {
        
      });
    });
  }

  @override
  void initState(){
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    final framePadding = MediaQuery.of(context).padding;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: cs.surface
        ),

        padding: EdgeInsets.only(left: 10, right: 10, top: framePadding.top + 10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text('Top fans on the app Route 65!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary),),
            ),
            Expanded(
              child: Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.secondary.withAlpha(15),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                  border: Border.all(color: Colors.grey.shade500, width: 2),
                ),
              
                padding: EdgeInsets.only(top: 20, bottom: framePadding.bottom + 10),
                child: loading ? Center(child: SizedBox(width: 200, child: Lottie.asset('assets/loading.json')),) 
                  : connectionError ? NoInternetPage(refreshCallback: loadData) :  SingleChildScrollView(
                  child: Column(spacing: 10, children: result.map((element) {
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      leading: CircleAvatar(radius: 30, backgroundImage: NetworkImage(element.img)),
                      title: Text(element.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis,),
                      trailing: Text((element.score * 10).toString(), style: TextStyle(fontSize: 18, color: cs.secondary, fontWeight: FontWeight.bold),),
                    );
                  }).toList()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
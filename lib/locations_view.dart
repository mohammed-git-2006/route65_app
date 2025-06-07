import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route65/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationsViewPage extends StatefulWidget {
  const LocationsViewPage({super.key});

  @override
  State<LocationsViewPage> createState() => LocationsViewPageState();
}

class LocationsViewPageState extends State<LocationsViewPage> {
  static final map65OtherBranch = LatLng(29.5218664,34.999778), map65MainBranch = LatLng(29.5322255,35.0038199);

  static get map65MidPoint {
    return LatLng(
      (map65MainBranch.latitude  + map65OtherBranch.latitude ) / 2.0,
      (map65MainBranch.longitude + map65OtherBranch.longitude) / 2.0,
    );
  }

  void openLocation(LatLng location) async {
    Uri uri = Uri.parse('https://maps.app.goo.gl/5TXstuZonzbguVVA7');
    if (location == map65MainBranch) {
      uri = Uri.parse('https://maps.app.goo.gl/NMEJK6Q8GjzZHSex7');
    }

    if (await canLaunchUrl(uri)) launchUrl(uri);
  }


  @override
  Widget build(BuildContext context) {
    final dic = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),

      body: SafeArea(
        child: Column(children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(dic.map_t1, style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: size.width * .065),),
          ),
          Expanded(
            child: Container(
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    border: Border.all(color: cs.secondary.withAlpha(50), width: 4),
                    borderRadius: BorderRadius.circular(30)
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: GoogleMap(
                      style: 'hyperspace',
                      initialCameraPosition: CameraPosition(target: map65MidPoint, zoom: 15),
                      markers: {
                        Marker(position: map65MainBranch, markerId: MarkerId('main_branch'), onTap: () => openLocation(map65MainBranch)),
                        Marker(position: map65OtherBranch, markerId: MarkerId('2nd_branch'), onTap: () => openLocation(map65OtherBranch)),
                      },
                    )
                )
            ),
          )
        ],),
      ),
    );
  }
}

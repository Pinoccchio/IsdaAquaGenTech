import 'package:flutter/material.dart';
import '../../../../../../components/theme/custom_text_style.dart';
import '../philippines_rpcmb.dart';

typedef DropdownItemBuilder<T> = DropdownMenuItem<T> Function(BuildContext context, T value);
typedef SelectedItemBuilder<T> = Widget Function(BuildContext context, T value);

class _PhilippineDropdownView<T> extends StatelessWidget {
  const _PhilippineDropdownView({
    Key? key,
    required this.choices,
    required this.onChanged,
    this.value,
    required this.itemBuilder,
    required this.hint,
    required this.selectedItemBuilder,
  }) : super(key: key);

  final List<T> choices;
  final ValueChanged<T?> onChanged;
  final T? value;
  final DropdownItemBuilder<T> itemBuilder;
  final SelectedItemBuilder<T> selectedItemBuilder;
  final Widget hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF40C4FF),
          width: 2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<T>(
            value: value,
            hint: DefaultTextStyle.merge(
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.normal,
                letterSpacing: 1.2,
              ),
              child: hint,
            ),
            items: choices.map((e) => itemBuilder.call(context, e)).toList(),
            onChanged: onChanged,
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF40C4FF),
            ),
            isExpanded: true,
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class PhilippineRegionDropdownView extends StatelessWidget {
  const PhilippineRegionDropdownView({
    Key? key,
    this.regions = philippineRegions,
    required this.onChanged,
    this.value,
    this.itemBuilder,
  }) : super(key: key);

  final List<Region> regions;
  final ValueChanged<Region?> onChanged;
  final Region? value;
  final DropdownItemBuilder<Region>? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return _PhilippineDropdownView(
      choices: regions,
      onChanged: onChanged,
      value: value,
      itemBuilder: (BuildContext context, e) {
        return itemBuilder?.call(context, e) ?? DropdownMenuItem(value: e, child: Text(e.regionName));
      },
      hint: Text(
        'SELECT REGION',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      selectedItemBuilder: (BuildContext context, Region value) {
        return Text(
          value.regionName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        );
      },
    );
  }
}

class PhilippineProvinceDropdownView extends StatelessWidget {
  const PhilippineProvinceDropdownView({
    Key? key,
    required this.provinces,
    required this.onChanged,
    this.value,
    this.itemBuilder,
  }) : super(key: key);

  final List<Province> provinces;
  final Province? value;
  final ValueChanged<Province?> onChanged;
  final DropdownItemBuilder<Province>? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return _PhilippineDropdownView(
      choices: provinces,
      onChanged: onChanged,
      value: value,
      itemBuilder: (BuildContext context, e) {
        return itemBuilder?.call(context, e) ?? DropdownMenuItem(value: e, child: Text(e.name));
      },
      hint: Text(
        'SELECT PROVINCE',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      selectedItemBuilder: (BuildContext context, Province value) {
        return Text(
          value.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        );
      },
    );
  }
}

class PhilippineMunicipalityDropdownView extends StatelessWidget {
  const PhilippineMunicipalityDropdownView({
    Key? key,
    required this.municipalities,
    required this.onChanged,
    this.value,
    this.itemBuilder,
  }) : super(key: key);

  final List<Municipality> municipalities;
  final Municipality? value;
  final ValueChanged<Municipality?> onChanged;
  final DropdownItemBuilder<Municipality>? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return _PhilippineDropdownView(
      choices: municipalities,
      onChanged: onChanged,
      value: value,
      itemBuilder: (BuildContext context, e) {
        return itemBuilder?.call(context, e) ?? DropdownMenuItem(value: e, child: Text(e.name));
      },
      hint: Text(
        'SELECT MUNICIPALITY',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      selectedItemBuilder: (BuildContext context, Municipality value) {
        return Text(
          value.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        );
      },
    );
  }
}

class PhilippineBarangayDropdownView extends StatelessWidget {
  const PhilippineBarangayDropdownView({
    Key? key,
    required this.barangays,
    required this.onChanged,
    this.value,
    this.itemBuilder,
  }) : super(key: key);

  final List<String> barangays;
  final String? value;
  final ValueChanged<String?> onChanged;
  final DropdownItemBuilder<String>? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return _PhilippineDropdownView(
      choices: barangays,
      onChanged: onChanged,
      value: value,
      itemBuilder: (BuildContext context, e) {
        return itemBuilder?.call(context, e) ?? DropdownMenuItem(value: e, child: Text(e));
      },
      hint: Text(
        'SELECT BARANGAY',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      selectedItemBuilder: (BuildContext context, String value) {
        return Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        );
      },
    );
  }
}


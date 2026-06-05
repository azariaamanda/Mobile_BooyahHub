// lib/data/models/services/banner_service.dart

import 'dart:developer';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../banner_model.dart';

class BannerService {
  final _supabase = Supabase.instance.client;

  Future<List<BannerModel>> getAllBanners() async {
    try {
      final response = await _supabase
          .from('banners')
          .select()
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => BannerModel.fromJson(e))
          .toList();
    } catch (e) {
      log('Error get all banners: $e');
      return [];
    }
  }

  Future<BannerModel?> createBanner(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('banners')
          .insert(data)
          .select()
          .single();
      return BannerModel.fromJson(response);
    } catch (e) {
      log('Error create banner: $e');
      return null;
    }
  }

  Future<BannerModel?> updateBanner(int id, Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('banners')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return BannerModel.fromJson(response);
    } catch (e) {
      log('Error update banner: $e');
      return null;
    }
  }

  Future<bool> deleteBanner(int id) async {
    try {
      await _supabase.from('banners').delete().eq('id', id);
      return true;
    } catch (e) {
      log('Error delete banner: $e');
      return false;
    }
  }

  // Upload gambar banner ke bucket posters
  static Future<String?> uploadBannerImage(File imageFile, String fileName) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Path: banners/nama_file.jpg
      final filePath = 'banners/$fileName';
      
      // Upload ke bucket posters
      await supabase.storage.from('posters').upload(filePath, imageFile);
      
      // Dapatkan public URL
      final publicUrl = supabase.storage.from('posters').getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      log('Error upload banner image: $e');
      return null;
    }
  }

  // Hapus gambar banner dari storage
  static Future<bool> deleteBannerImage(String imageUrl) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Extract path dari URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      final postersIndex = pathSegments.indexOf('posters');
      if (postersIndex != -1 && postersIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(postersIndex + 1).join('/');
        await supabase.storage.from('posters').remove([filePath]);
        return true;
      }
      return false;
    } catch (e) {
      log('Error delete banner image: $e');
      return false;
    }
  }
}
import '../models/weather_models.dart';

class GeminiAssistantService {
  /// Generates meteorologist advice response based on weather and question
  static Future<String> askWeatherAssistant({
    required String question,
    required FullWeatherData weatherData,
  }) async {
    // Simulate brief network latency for realistic chat feel
    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedQ = question
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
    final qLower = normalizedQ;
    final locName = weatherData.location.name;
    final temp = weatherData.current.temperatureCelsius.toInt();
    final cond = weatherData.current.conditionAr;

    if (normalizedQ.contains("ملابس") || normalizedQ.contains("البس") || normalizedQ.contains("ارتدي")) {
      if (temp < 15) {
        return "درجة الحرارة الحالية في $locName تبلغ $temp°م ($cond). أنصحك بارتداء معطف شتوي دافئ أو سترة صوفية، خاصة في ساعات المساء والصباح الباكر.";
      } else if (temp < 23) {
        return "الأجواء في $locName معتدلة وتميل للاعتدال اللطيف ($temp°م). تكفي ملابس ربيعية/خريفية مع سترة خفيفة تحسباً لنسمات الهواء المنعشة ليلاً.";
      } else {
        return "الطقس حار نسبياً في $locName ($temp°م). يُنصح بملابس قطنية خفيفة وفاتحة اللون، وارتداء نظارة شمسية أو قبعة عند الخروج تحت أشعة الشمس المباشرة.";
      }
    }

    if (qLower.contains("مطر") || qLower.contains("شتي") || qLower.contains("امطار")) {
      final rainProb = weatherData.dailyList.isNotEmpty ? weatherData.dailyList.first.precipitationProb : 0;
      if (rainProb > 40) {
        return "نعم، هناك احتمالية لهطول الأمطار بنسبة تقارب $rainProb% في $locName. يُفضل أخذ مظلة معك والانتباه للطرقات الزلقة.";
      } else {
        return "فرص الأمطار الحالية في $locName منخفضة ومستقرة، والجو $cond مع سماء مستقرة بوجه عام.";
      }
    }

    if (qLower.contains("زراعة") || qLower.contains("محصول") || qLower.contains("ري") || qLower.contains("شجر")) {
      return "في $locName تبلغ الحرارة $temp°م والرطوبة ${weatherData.current.humidity}%. هذه معلومات جوية عامة فقط، ولا تكفي وحدها لتحديد مواعيد الري أو التسميد أو مكافحة الآفات. يُرجى الرجوع إلى الإرشاد الزراعي المحلي وبيانات التربة والمحصول.";
    }

    if (qLower.contains("سفر") || qLower.contains("طريق") || qLower.contains("سيارة")) {
      return "لا تتوفر لدي بيانات مباشرة عن حالة الطرق أو الحوادث أو إغلاقاتها في $locName. الطقس الحالي المبلغ عنه هو $cond، وسرعة الرياح ${weatherData.current.windSpeedKmh.toInt()} كم/س. لا يمكن استنتاج سلامة الطريق من بيانات الطقس وحدها؛ تحقق من الجهات المرورية الرسمية قبل السفر.";
    }

    return "مرحباً بك! أنا مساعد الطقس المحلي في MCNC. الأجواء حالياً في $locName تسجل $temp°م وحالة الطقس: $cond، وسرعة الرياح ${weatherData.current.windSpeedKmh.toInt()} كم/س. يمكنك سؤالي عن نصائح اللباس، مواعيد السفر، أو الإرشادات الزراعية لأي محافظة سورية!";
  }
}

// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/yard/
// ----------------------------------------------------------
//
// Реализация распаковки EFD-файла на основе обработки:
// https://infostart.ru/public/618906/
//
// ----------------------------------------------------------

Перем Лог;

#Область ПрограммныйИнтерфейс

// Процедура - извлекает указанные файлы из архива в формате EFD (1С)
//
// Параметры:
//  ПутьКАрхивуEFD      - Строка          - путь к архиву в формате EFD
//  КаталогРаспаковки   - Строка          - путь к каталогу для сохранения результата распаковки
//  ВыбранныеФайлы      - Строка          - имя файла или список файлов для распаковки
//                        Массив(Строка)    если не указан, то распаковываются все файлы
//  РаспаковкаКаталогов - Строка          - вариант распаковки каталогов
//
Процедура РаспаковатьШаблонКонфигурации1С(Знач ПутьКАрхивуEFD,
                                          Знач КаталогРаспаковки,
                                          Знач ВыбранныеФайлы = "",
                                          Знач РаспаковкаКаталогов = "") Экспорт

	ВремФайлАрхива = Новый Файл(ПутьКАрхивуEFD);

	ПутьКФайлуDeflate = ИзвлечьАрхивDeflate(ПутьКАрхивуEFD);
	
	ЗаписатьВыбранныеФайлы(ПутьКФайлуDeflate, КаталогРаспаковки, ВыбранныеФайлы, РаспаковкаКаталогов);

	УдалитьФайлы(ПутьКФайлуDeflate);

КонецПроцедуры // РаспаковатьШаблонКонфигурации1С()

// Процедура - выполняет распаковку архива с использованием установленного в системе архиватора 7-zip
//   
// Параметры:
//  ПутьКАрхиву         - Строка     - путь к архиву
//  КаталогРаспаковки   - Строка     - путь к каталогу для сохранения результата распаковки
//
Процедура РаспаковатьАрхив(Знач ПутьКАрхиву, Знач КаталогРаспаковки) Экспорт
	
	ПутьК7ЗИП = Найти7Zip();
	
	Если НЕ ЗначениеЗаполнено(ПутьК7ЗИП) Тогда
		ВызватьИсключение "7-Zip не найден";
	КонецЕсли;

	ДанныеИсхФайла = Новый Файл(ПутьКАрхиву);

	ИмяФайлаОшибокАрхивации = ДанныеИсхФайла.Путь + "7z_error_messages.txt";

	КомандаАрхиватора = СтрШаблон("""%1"" x -aoa -y -o%2 ""%3""",
	                              ПутьК7ЗИП,
	                              КаталогРаспаковки,
	                              ПутьКАрхиву);
	
	КодВозврата = 0;
	ЗапуститьПриложение(КомандаАрхиватора, ДанныеИсхФайла.Путь, Истина, КодВозврата);

	Если НЕ КодВозврата = 0 Тогда

		ФайлОшибокАрх = Новый Файл(ИмяФайлаОшибокАрхивации);
		Если ФайлОшибокАрх.Существует() Тогда
			ЧтениеФайла = Новый ЧтениеТекста(ИмяФайлаОшибокАрхивации);
			СтрокаФайлаОшибок = ЧтениеФайла.ПрочитатьСтроку();
			Пока СтрокаФайлаОшибок <> Неопределено Цикл
				СтрокаФайлаОшибок = ЧтениеФайла.ПрочитатьСтроку();
			КонецЦикла;
			ЧтениеФайла.Закрыть();
			УдалитьФайлы(ИмяФайлаОшибокАрхивации);
		КонецЕсли;

		Возврат;
	КонецЕсли;

КонецПроцедуры // РаспаковатьАрхив()

#КонецОбласти // ПрограммныйИнтерфейс

#Область СлужебныеПроцедурыИФункцииРаботыАрхивами

// Функция - извлекает из архива в формате EFD (1С) архив в формате Deflate
// и возвращает путь к извлеченному файлу
//
// Параметры:
//  ПутьКАрхивуEFD      - Строка     - путь к архиву в формате EFD
//  КаталогРаспаковки   - Строка     - путь к каталогу для сохранения результата распаковки,
//                                     если не указан то совпадает с расположением архива EFD
//
// Возвращаемое значение:
//  Строка  - путь к извлеченному файлу
//
Функция ИзвлечьАрхивDeflate(Знач ПутьКАрхивуEFD, Знач КаталогРаспаковки = "")

	ВремФайлАрхива = Новый Файл(ПутьКАрхивуEFD);

	Если НЕ ЗначениеЗаполнено(КаталогРаспаковки) Тогда
		КаталогРаспаковки = ВремФайлАрхива.Путь;
	КонецЕсли;

	ИмяФайлаDeflate = СтрШаблон("%1_%2.ifl", ВремФайлАрхива.ИмяБезРасширения, Новый УникальныйИдентификатор());

	ПутьКФайлуZIP = ПреобразоватьАрхивEFDвZIP(ПутьКАрхивуEFD, ИмяФайлаDeflate, КаталогРаспаковки);

	ИзвлечьФайлИзАрхиваZIP(ПутьКФайлуZIP, КаталогРаспаковки);

	УдалитьФайлы(ПутьКФайлуZIP);

	Возврат ОбъединитьПути(КаталогРаспаковки, ИмяФайлаDeflate);

КонецФункции // ИзвлечьАрхивDeflate()

// Функция - преобразует архив в формате EFD (1С) в формат ZIP
// путем добавления необходимых заголовков
//
// Параметры:
//  ПутьКАрхивуEFD      - Строка     - путь к архиву в формате EFD
//  ИмяФайлаDeflate     - Строка     - тут будет возвращено имя файла архива в формате EFD
//  КаталогРаспаковки   - Строка     - путь к каталогу для сохранения результата преобразования,
//                                     если не указан то совпадает с расположением архива EFD
//
// Возвращаемое значение:
//  Строка  - путь к созданному файлу ZIP
//
Функция ПреобразоватьАрхивEFDвZIP(Знач ПутьКАрхивуEFD, Знач ИмяФайлаDeflate, Знач КаталогРаспаковки = "")

	// Структура ZIP файла:
	// https://blog2k.ru/archives/3391
	// https://users.cs.jmu.edu/buchhofp/forensics/formats/pkzip.html
	// https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
	
	ВремФайлАрхива = Новый Файл(ПутьКАрхивуEFD);

	Если НЕ ЗначениеЗаполнено(КаталогРаспаковки) Тогда
		КаталогРаспаковки = ВремФайлАрхива.Путь;
	КонецЕсли;

	ИмяФайлаZIP     = СтрШаблон("%1_%2.zip", ВремФайлАрхива.ИмяБезРасширения, Новый УникальныйИдентификатор());

	ПутьКАрхивуZIP = ОбъединитьПути(КаталогРаспаковки, ИмяФайлаZIP);

	Бинарник = Новый ДвоичныеДанные(ПутьКАрхивуEFD);
	
	ДлинаИмениСжатогоФайла    = СтрДлина(ИмяФайлаDeflate);
	РазмерСжатогоФайла        = Бинарник.Размер();
	CRC                       = 0;
	РазмерРаспакованногоФайла = Pow(2, 32) - 1; // максимально возможный размер
	ДатаВремя                 = ТекущаяДата();
	ВремяФайла                = ВремяFAT(ДатаВремя);
	ДатаФайла                 = ДатаFAT(ДатаВремя);
	
	РазмерZIP = ПолучитьРазмерZIPФайла(РазмерСжатогоФайла, ДлинаИмениСжатогоФайла);
	
	БинарныйБуфер = Новый БуферДвоичныхДанных(РазмерZIP);
	
	См0  = 0;
	См4  = 4;
	См6  = 6;
	См8  = 8;
	См10 = 10;
	См12 = 12;
	См14 = 14;
	См16 = 16;
	См18 = 18;
	См20 = 20;
	См22 = 22;
	См24 = 24;
	См26 = 26;
	См28 = 28;
	См30 = 30;
	См32 = 32;
	См34 = 34;
	См36 = 36;
	См38 = 38;
	См42 = 42;

	// [Local File Header]
	ДлинаФиксированнойЧастиLFH = 30;
	
	Сигнатура1           = 67324752;     // Обязательная сигнатура 0x04034B50
	ВерсияДляРаспаковки  = 20;           // Минимальная версия для распаковки
	БитовыйФлаг          = 2050;         // Битовый флаг
	МетодСжатия          = 8;            // Метод сжатия (0 - без сжатия, 8 - deflate)
	
	БинарныйБуфер.ЗаписатьЦелое32(См0 , Сигнатура1);                // Обязательная сигнатура 0x04034B50
	БинарныйБуфер.ЗаписатьЦелое16(См4 , ВерсияДляРаспаковки);       // Минимальная версия для распаковки
	БинарныйБуфер.ЗаписатьЦелое16(См6 , БитовыйФлаг);               // Битовый флаг
	БинарныйБуфер.ЗаписатьЦелое16(См8 , МетодСжатия);               // Метод сжатия (0 - без сжатия, 8 - deflate)
	БинарныйБуфер.ЗаписатьЦелое16(См10, ВремяФайла);                // Время модификации файла
	БинарныйБуфер.ЗаписатьЦелое16(См12, ДатаФайла);                 // Дата модификации файла
	БинарныйБуфер.ЗаписатьЦелое32(См14, CRC);                       // Контрольная сумма
	БинарныйБуфер.ЗаписатьЦелое32(См18, РазмерСжатогоФайла);        // Сжатый размер
	БинарныйБуфер.ЗаписатьЦелое32(См22, РазмерРаспакованногоФайла); // Несжатый размер
	БинарныйБуфер.ЗаписатьЦелое16(См26, ДлинаИмениСжатогоФайла);    // Длина название файла
	БинарныйБуфер.ЗаписатьЦелое16(См28, 0);                         // Длина поля с дополнительными данными
	
	// Название файла
	Для й = 0 По ДлинаИмениСжатогоФайла - 1 Цикл
		БинарныйБуфер.Установить(ДлинаФиксированнойЧастиLFH + й, КодСимвола(Сред(ИмяФайлаDeflate, й + 1, 1)));
	КонецЦикла;
	
	// [Сжатые данные]
	БуферСжатыхДанных = Новый БуферДвоичныхДанных(РазмерСжатогоФайла);
	
	Поток = Бинарник.ОткрытьПотокДляЧтения();
	Поток.Прочитать(БуферСжатыхДанных, 0, РазмерСжатогоФайла);
	Поток.Закрыть();
	
	БинарныйБуфер.Записать(ДлинаФиксированнойЧастиLFH + ДлинаИмениСжатогоФайла, БуферСжатыхДанных);
	
	ТекущееСмещение = ДлинаФиксированнойЧастиLFH + ДлинаИмениСжатогоФайла + РазмерСжатогоФайла;
	
	// [Central directory file header]
	ДлинаФиксированнойЧастиCDFH	= 46;
	ДлинаДополнительныхДанных	= 0; // Длина поля с дополнительными данными
	
	Сигнатура2           = 33639248;     // Обязательная сигнатура 0x02014B50
	ВерсияДляСоздания    = 814;          // Версия для создания
	ВнешниеАтрибутыФайла = 2176057344;   // Внешние аттрибуты файла

	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + См0 , Сигнатура2);                 // Обязательная сигнатура 0x02014B50
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См4 , ВерсияДляСоздания);          // Версия для создания
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См6 , ВерсияДляРаспаковки);        // Минимальная версия для распаковки
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См8 , БитовыйФлаг);                // Битовый флаг
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См10, МетодСжатия);
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См12, ВремяФайла);                 // Время модификации файла
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См14, ДатаФайла);                  // Дата модификации файла
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + См16, CRC);                        // Контрольная сумма
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + См20, РазмерСжатогоФайла);         // Сжатый размер
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + См24, РазмерРаспакованногоФайла);  // Несжатый размер
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См28, ДлинаИмениСжатогоФайла);     // Длина название файла
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См30, ДлинаДополнительныхДанных);
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См32, 0);                          // Длина комментариев к файлу
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См34, 0);                          // Номер диска
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См36, 0);                          // Внутренние аттрибуты файла
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + См38, ВнешниеАтрибутыФайла);       // Внешние аттрибуты файла
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + См42, 0);                     // Смещение до структуры LocalFileHeader
	
	// Название файла
	Для й = 0 По ДлинаИмениСжатогоФайла - 1 Цикл
		СимволИмениФайла = КодСимвола(Сред(ИмяФайлаDeflate, й + 1, 1));
		БинарныйБуфер.Установить(ТекущееСмещение + ДлинаФиксированнойЧастиCDFH + й, СимволИмениФайла);
	КонецЦикла;
	
	ТекущееСмещение = ТекущееСмещение + ДлинаФиксированнойЧастиCDFH + ДлинаИмениСжатогоФайла;
	
	ТекущееСмещение = ТекущееСмещение + ДлинаДополнительныхДанных;
	
	// [End of central directory record (EOCD)]
	РазмерCentralDirectory		= ДлинаФиксированнойЧастиCDFH + ДлинаИмениСжатогоФайла + ДлинаДополнительныхДанных;
	СмещениеCentralDirectory	= ДлинаФиксированнойЧастиLFH  + ДлинаИмениСжатогоФайла + РазмерСжатогоФайла;
	
	Сигнатура3 = 101010256; // Обязательная сигнатура 0x06054B50

	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + См0,  Сигнатура3);            // Обязательная сигнатура 0x06054B50
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См4,  0);                     // Номер диска
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См6,  0);  // Номер диска, где находится начало Central Directory
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См8,  1);  // Количество записей в Central Directory в текущем диске
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См10, 1);                        // Всего записей в Central Directory
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + См12, РазмерCentralDirectory);   // Размер Central Directory
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + См16, СмещениеCentralDirectory); // Смещение Central Directory
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + См20, 0);                        // Длина комментария
	
	ПотокВПамяти = Новый ПотокВПамяти(БинарныйБуфер);
	
	НовыйБинарник = ПотокВПамяти.ЗакрытьИПолучитьДвоичныеДанные();
	НовыйБинарник.Записать(ПутьКАрхивуZIP);
	
	Возврат ПутьКАрхивуZIP;

КонецФункции // ПреобразоватьАрхивEFDвZIP()

// Функция - вычисляет размер ZIP-файла в байтах
//
// Параметры:
//  РазмерСжатыхДанных          - Число     - размер данных файла в байтах
//  РазмерИмениИсходногоФайла   - Число     - размер имени сжатого файла в байтах
//
// Возвращаемое значение:
//  Число  - размер файла в байтах
//
Функция ПолучитьРазмерZIPФайла(РазмерСжатыхДанных, РазмерИмениИсходногоФайла)

	Р0 = 0; // 0-е смещение
	Р2 = 2; // смещение 2 байта
	Р4 = 4; // смещение 4 байта

	РазмерLocalFileHeader             = Р4 + Р2 + Р2 + Р2 + Р2 + Р2 + Р4 + Р4 + Р4 + Р2 + Р2
									  + РазмерИмениИсходногоФайла + Р0;
	
	РазмерCentralDirectoryFileHeader  = Р4 + Р2 + Р2 + Р2 + Р2 + Р2 + Р2 + Р4 + Р4 + Р4 + Р2 + Р2 + Р2 + Р2 + Р2
									  + Р4 + Р4 + РазмерИмениИсходногоФайла + Р0 + Р0;
	
	РазмерEndOfCentralDirectoryRecord = Р4 + Р2 + Р2 + Р2 + Р2 + Р4 + Р4 + Р2 + Р0;
	
	Возврат РазмерLocalFileHeader +
			РазмерСжатыхДанных +
			РазмерCentralDirectoryFileHeader +
			РазмерEndOfCentralDirectoryRecord;

КонецФункции // ПолучитьРазмерZIPФайла()

// Функция - читает структуру файлов в архиве Deflate
//
// Параметры:
//  ПутьКФайлуDeflate     - Строка   - путь к файлу Deflate для обработки
//
// Возвращаемое значение:
//  Массив(Структура)   - список файлов в архиве
//      *Имя                - Строка   - имя файла
//      *ПолноеИмя          - Строка   - имя файла с путем
//      *Размер             - Число    - размер файла в байтах
//      *Смещение           - Число    - абсолютное смещение файла
//
Функция ПолучитьСписокФайловВАрхиве(ПутьКФайлуDeflate)

	ФайлыВАрхиве = Новый Массив();
	
	Бинарник = Новый ДвоичныеДанные(ПутьКФайлуDeflate);
	Поток = Бинарник.ОткрытьПотокДляЧтения();
	НачальноеСмещение = 0;
	
	См4  = 4;
	См8  = 8;
	См16 = 16;

	// первые 4 байта - возможно, заголовок или кол-во пакетов данных
	НачальноеСмещение = НачальноеСмещение + См4;
	
	КолВоЯзыковыхБлоков = ПрочитатьРазмер(Поток, НачальноеСмещение);
	НачальноеСмещение = НачальноеСмещение + См4;
	
	Для й = 1 По КолВоЯзыковыхБлоков Цикл
		ДлинаЯзыковогоБлока = ПрочитатьРазмер(Поток, НачальноеСмещение);
		НачальноеСмещение = НачальноеСмещение + ДлинаЯзыковогоБлока;
	КонецЦикла;
	
	КолВоФайлов = ПрочитатьРазмер(Поток, НачальноеСмещение);
	НачальноеСмещение = НачальноеСмещение + См4;
	
	СмещениеЗаголовка = НачальноеСмещение;
	Для й = 1 По КолВоФайлов Цикл
		ДлинаБлокаИмениФайла	= ПрочитатьРазмер(Поток, СмещениеЗаголовка);
		СмещениеЗаголовка = СмещениеЗаголовка + ДлинаБлокаИмениФайла;
	КонецЦикла;

	СмещениеИмениФайла = НачальноеСмещение;

	Для й = 1 По КолВоФайлов Цикл
		ДлинаБлокаИмениФайла = ПрочитатьРазмер(Поток, СмещениеИмениФайла);
		ДлинаИмениФайла      = ПрочитатьРазмер(Поток, СмещениеИмениФайла + См4);
		ПолноеИмяФайла       = ПрочитатьСтрокуИзПотока(Поток, СмещениеИмениФайла + См8, ДлинаБлокаИмениФайла - См8 - См16);

		ЧастиПути = СтрРазделить(ПолноеИмяФайла, "\");
		ИмяФайла = ЧастиПути[ЧастиПути.ВГраница()];
		
		Если ДлинаИмениФайла <> СтрДлина(ПолноеИмяФайла) Тогда
			Сообщить("Ошибка чтения имени файла №" + й);
			Продолжить;
		КонецЕсли;
		
		СмещениеФайла = ПрочитатьРазмер(Поток, СмещениеИмениФайла + ДлинаБлокаИмениФайла - См8);
		РазмерФайла   = ПрочитатьРазмер(Поток, СмещениеИмениФайла + ДлинаБлокаИмениФайла - См4);
		
		ОписаниеФайла = Новый Структура("Имя, ПолноеИмя, Размер, Смещение");
		ОписаниеФайла.Имя       = ИмяФайла;
		ОписаниеФайла.ПолноеИмя = ПолноеИмяФайла;
		ОписаниеФайла.Размер    = РазмерФайла;
		ОписаниеФайла.Смещение  = СмещениеЗаголовка + СмещениеФайла;
		ФайлыВАрхиве.Добавить(ОписаниеФайла);

		СмещениеИмениФайла = СмещениеИмениФайла + ДлинаБлокаИмениФайла;
	КонецЦикла;
	
	Поток.Закрыть();

	Возврат ФайлыВАрхиве;

КонецФункции // ПолучитьСписокФайловВАрхиве()

// Процедура - извлекает указанные файлы из архива Deflate
// и сохраняет их в указанный каталог
//
// Параметры:
//  ПутьКФайлуDeflate   - Строка         - путь к файлу Deflate для обработки
//  КаталогРаспаковки   - Строка         - путь к каталогу для сохранения извлеченных файлов
//  ВыбранныеФайлы      - Строка         - имя файла или список файлов для распаковки
//                        Массив(Строка)   если не указан, то распаковываются все файлы
//  РаспаковкаКаталогов - Строка         - вариант распаковки каталогов
//
Процедура ЗаписатьВыбранныеФайлы(ПутьКФайлуDeflate,
                                 Знач КаталогРаспаковки,
                                 Знач ВыбранныеФайлы = "",
                                 Знач РаспаковкаКаталогов = "")

	ФайлыВАрхиве = ПолучитьСписокФайловВАрхиве(ПутьКФайлуDeflate);

	МассивФайлов = Новый Массив();

	Если ТипЗнч(ВыбранныеФайлы) = Тип("Строка") Тогда
		Если ЗначениеЗаполнено(ВыбранныеФайлы) Тогда
			МассивФайлов.Добавить(ВыбранныеФайлы);
		КонецЕсли;
	ИначеЕсли ТипЗнч(ВыбранныеФайлы) = Тип("Массив") Тогда
		МассивФайлов = ВыбранныеФайлы;
	Иначе
		ВызватьИсключение СтрШаблон("Некорректно указан список извлекаемых файлов ""%1""!", ВыбранныеФайлы);
	КонецЕсли;

	Если НЕ ЗначениеЗаполнено(РаспаковкаКаталогов) Тогда
		РаспаковкаКаталогов = ВариантРаспаковкиКаталогаПоУмолчанию(ФайлыВАрхиве);
	КонецЕсли;

	ОбщийПуть = "";
	Если РаспаковкаКаталогов = Перечисления.ВариантыРаспаковкиКаталогов.БезОбщихКаталогов Тогда
		ОбщийПуть = Служебный.ОбщийПутьФайлов(ФайлыВАрхиве);
	КонецЕсли;

	Бинарник = Новый ДвоичныеДанные(ПутьКФайлуDeflate);
	Поток = Бинарник.ОткрытьПотокДляЧтения();
	
	Для Каждого ТекСтрока Из ФайлыВАрхиве Цикл

		Если МассивФайлов.Количество() > 0 Тогда
			Если МассивФайлов.Найти(ТекСтрока.Имя) = Неопределено
			   И МассивФайлов.Найти(ТекСтрока.ПолноеИмя) = Неопределено Тогда
				Продолжить;
			КонецЕсли;
		КонецЕсли;

		КаталогРаспаковкиФайла = КаталогРаспаковкиФайла(ТекСтрока, КаталогРаспаковки, ОбщийПуть, РаспаковкаКаталогов);

		ЗаписатьФайл(Поток, ТекСтрока, КаталогРаспаковкиФайла);

	КонецЦикла;

	Поток.Закрыть();

КонецПроцедуры // ЗаписатьВыбранныеФайлы()

// Процедура - сохраняет указанный файл из потока по указанному пути
// 
// Параметры:
//  Поток               - Поток        - поток с данными файла
//  ОписаниеФайла       - Структура    - описание файла в архиве
//      *Имя                - Строка       - имя файла
//      *ПолноеИмя          - Строка       - имя файла с путем
//      *Размер             - Число        - размер файла в байтах
//      *Смещение           - Число        - смещение файла в потоке
//  КаталогРаспаковки   - Строка       - путь к каталогу для сохранения файла
//
Процедура ЗаписатьФайл(Поток, Знач ОписаниеФайла, Знач КаталогРаспаковки)

	БуферДанные = Новый БуферДвоичныхДанных(ОписаниеФайла.Размер);
	Поток.Перейти(ОписаниеФайла.Смещение, ПозицияВПотоке.Начало);
	Поток.Прочитать(БуферДанные, 0, ОписаниеФайла.Размер);
	
	ПутьКФайлу = ОбъединитьПути(КаталогРаспаковки, ОписаниеФайла.Имя);

	ОбеспечитьКаталог(ПутьКФайлу, Истина);

	ЗаписьДанных = Новый ЗаписьДанных(ПутьКФайлу);
	ЗаписьДанных.ЗаписатьБуферДвоичныхДанных(БуферДанные);
	ЗаписьДанных.Закрыть();
	
	Лог.Информация(СтрШаблон("Записан файл %1", ПутьКФайлу));

КонецПроцедуры // ЗаписатьФайл()

#КонецОбласти // СлужебныеПроцедурыИФункцииРаботыАрхивами

#Область СлужебныеПроцедурыИФункции

// Преобразует переданное в виде строки число из системы счисления с указанным основанием
// в десятичную систему счисления
// 
// Параметры:
//  СтрЧисло        - Строка    - число в виде строки для преобразования
//  Основание       - Число     - основание системы счисления
//
// Возвращаемое значение:
//  Число  - десятичное число
//
Функция RadixToDec(СтрЧисло, Основание = 10)

	МинОснование = 2;
	МаксОснование = 36;
	Основание10 = 10;

	Если Основание < МинОснование ИЛИ Основание > МаксОснование Тогда
		ВызватьИсключение "Преобразование между системами счисления возможно для оснований от 2 до 36";
	КонецЕсли;
	
	Если Основание = Основание10 Тогда
		Возврат Число(СтрЧисло);
	КонецЕсли;
	
	Алфавит = "0123456789ABCDEFGHIGKLMNOPQRSTUVWXYZ";
	ИтоговоеЧисло = 0;
	
	Для й = 0 По СтрДлина(СтрЧисло) - 1 Цикл
		Цифра = Сред(СтрЧисло, СтрДлина(СтрЧисло) - й, 1);
		ЗначениеЦифры = СтрНайти(Алфавит, Цифра) - 1;
		
		Если ЗначениеЦифры < Основание Тогда
			ИтоговоеЧисло = ИтоговоеЧисло + ЗначениеЦифры * Pow(Основание, й);	
		Иначе 
			ВызватьИсключение "Число за пределами возможного для данного основания";
		КонецЕсли;
	КонецЦикла;
	
	Возврат ИтоговоеЧисло;

КонецФункции // RadixToDec()

// Преобразует переданное число из десятичной системы счисления
// в систему счисления с указанным основанием
// 
// Параметры:
//  ДесятичноеЧисло   - Строка    - число для преобразования
//  Основание         - Число     - основание системы счисления результата
//  МаксДлина         - Число     - фиксированная длина результата
//
// Возвращаемое значение:
//  Строка  - число в виде строки - результат преобразования
//
Функция DecToRadix(Знач ДесятичноеЧисло, Основание = 10, МаксДлина = 0)

	МинОснование = 2;
	МаксОснование = 36;
	Основание10 = 10;

	Если Основание < МинОснование ИЛИ Основание > МаксОснование Тогда
		ВызватьИсключение "Преобразование между системами счисления возможно для оснований от 2 до 36";
	КонецЕсли;
	
	Если ДесятичноеЧисло <= 0 Тогда
		Возврат "0";
	КонецЕсли;
	
	Если Основание = Основание10 Тогда
		Возврат Формат(ДесятичноеЧисло, "ЧГ=0");
	КонецЕсли;
	
	Алфавит = "0123456789ABCDEFGHIGKLMNOPQRSTUVWXYZ";
	Буфер = "";
	Результат = "";
	
	Пока ДесятичноеЧисло > 0 Цикл
		Остаток = ДесятичноеЧисло % Основание;
		Буфер = Буфер + Сред(Алфавит, Остаток + 1, 1);
		ДесятичноеЧисло = Цел(ДесятичноеЧисло / Основание);
	КонецЦикла;
	
	Для й = 1 По МаксДлина - СтрДлина(Буфер) Цикл
		Результат = Результат + "0";
	КонецЦикла;
	
	Для й = -СтрДлина(Буфер) По -1 Цикл
		Результат = Результат + Сред(Буфер, -й, 1);
	КонецЦикла;
	
	Возврат Результат;

КонецФункции // DecToRadix()

// Функция - выделяет время из указанной даты и преобразует в формат для файловой системы FAT
// 
// Параметры:
//  ДатаВремя   - Дата    - дата для преобразования
//
// Возвращаемое значение:
//  Число  - время в формате для файловой системы FAT
//
Функция ВремяFAT(ДатаВремя)
	
	// https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#Format_Time
	
	Час = Час(ДатаВремя);
	Мин = Минута(ДатаВремя);
	Сек = Цел(Секунда(ДатаВремя) / 2);
	
	ВремяБинарное = DecToRadix(Час, 2, 5) + DecToRadix(Мин, 2, 6) + DecToRadix(Сек, 2, 5);
	
	Возврат RadixToDec(ВремяБинарное, 2);

КонецФункции // ВремяFAT()

// Функция - выделяет дату из указанной даты и преобразует в формат для файловой системы FAT
// 
// Параметры:
//  ДатаВремя   - Дата    - дата для преобразования
//
// Возвращаемое значение:
//  Число  - дата в формате для файловой системы FAT
//
Функция ДатаFAT(ДатаВремя)
	
	// https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#Format_Date
	
	НачГод = 1980;

	Год = Год(ДатаВремя) - НачГод;
	Мес = Месяц(ДатаВремя);
	Ден = День(ДатаВремя);
	
	ДатаБинарная = DecToRadix(Год, 2, 7) + DecToRadix(Мес, 2, 4) + DecToRadix(Ден, 2, 5);
	
	Возврат RadixToDec(ДатаБинарная, 2);

КонецФункции // ДатаFAT()

// Функция - читает 4 байта из потока по указанному смещения
// используется для чтения размера файла из заголовка архива
//
// Параметры:
//	Поток       - Поток   - поток для чтения
//	Смещение    - Число   - смещение от начала потока
//
// Возвращаемое значение:
//	Число     - размер файла
//
Функция ПрочитатьРазмер(Поток, Смещение)

	БуферРазмер = Новый БуферДвоичныхДанных(4);
	Поток.Перейти(Смещение, ПозицияВПотоке.Начало);
	Поток.Прочитать(БуферРазмер, 0, 4);

	Возврат БуферРазмер.ПрочитатьЦелое32(0);

КонецФункции // ПрочитатьРазмер()

// Функция - читает строку указанного размера из потока по указанному смещению
//
// Параметры:
//	Поток       - Поток   - поток для чтения
//	Смещение    - Число   - смещение от начала потока
//	Размер      - Число   - размер считываемых данных в байтах
//
// Возвращаемое значение:
//	Строка     - прочитанная строка
//
Функция ПрочитатьСтрокуИзПотока(Поток, Смещение, Размер)

	БуферСтроки = Новый БуферДвоичныхДанных(Размер);
	Поток.Перейти(Смещение, ПозицияВПотоке.Начало);
	Поток.Прочитать(БуферСтроки, 0, Размер);

	Возврат ПолучитьСтрокуИзБуфера(БуферСтроки);

КонецФункции // ПрочитатьСтрокуИзПотока()

// Функция - читает буфер и преобразует результат чтения в строку
//
// Параметры:
//	БинарныйБуфер    - БуферДвоичныхДанных   - буфер для чтения
//
// Возвращаемое значение:
//	Строка     - прочитанная строка
//
Функция ПолучитьСтрокуИзБуфера(БинарныйБуфер)
	
	Результат = "";
	ДлинаБинарника = БинарныйБуфер.Размер;
	Позиция = 0;
	Сдвиг = 2;

	Пока Позиция < ДлинаБинарника Цикл
		Код = БинарныйБуфер.ПрочитатьЦелое16(Позиция);
		Позиция = Позиция + Сдвиг;
		Результат = Результат + Символ(Код);
	КонецЦикла;
	
	Возврат Результат;

КонецФункции // ПолучитьТекстИзБуфера()

// Процедура - извлекает первый файл из ZIP-архива 
//
// Параметры:
//  ПутьКАрхивуZIP      - Строка     - путь к ZIP-архиву
//  КаталогРаспаковки   - Строка     - путь к каталогу для сохранения результата распаковки,
//                                     если не указан то совпадает с расположением ZIP-архива
//
Процедура ИзвлечьФайлИзАрхиваZIP(ПутьКАрхивуZIP, КаталогРаспаковки = "")

	ВремФайлАрхива = Новый Файл(ПутьКАрхивуZIP);

	Если НЕ ЗначениеЗаполнено(КаталогРаспаковки) Тогда
		КаталогРаспаковки = ВремФайлАрхива.Путь;
	КонецЕсли;

	Файл = Новый ЧтениеZipФайла(ПутьКАрхивуZIP);
	
	Попытка
		Файл.Извлечь(Файл.Элементы[0], КаталогРаспаковки);
		//файл извлечется, хотя здесь возникнет исключение из-за некорректных размера файла и контрольной суммы
	Исключение
		ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		ТекстСообщения = СтрШаблон("Ошибка извлечения файла ""%1"" из архива ""%2"": %3%4",
		                           Файл.Элементы[0].Имя,
		                           ПутьКАрхивуZIP,
		                           Символы.ПС,
		                           ТекстОшибки);
		ПараметрыПриложения.Лог().Отладка(ТекстСообщения);
	КонецПопытки;

	Файл.Закрыть();

КонецПроцедуры // ИзвлечьФайлИзАрхиваZIP()

// Функция - ищет и возвращает путь к архиватору 7-zip
//
// Возвращаемое значение:
//  Строка   - путь к исполняемому файлу архиватора 7-zip
//
Функция Найти7ZIP()

	// Предполагаем, что для X64_86 7-Zip будет 64-битный
	КаталогПрограмм = "C:\" + "Program Files";
	ИмяИсполняемогоФайла = "7z.exe";

	Массив7ZIP = НайтиФайлы(КаталогПрограмм, ИмяИсполняемогоФайла, True);

	Если Массив7ZIP.Количество() = 0 Тогда
		Возврат Неопределено;
	Иначе
		Возврат Массив7ZIP[0].ПолноеИмя;
	КонецЕсли;

КонецФункции // Найти7ZIP()

// Функция - возвращает вариант распаковки каталогов по умолчанию
//
// Параметры:
//  ФайлыВАрхиве     - Массив(Структура)   - список файлов в архиве
//      *Имя             - Строка              - имя файла
//      *ПолноеИмя       - Строка              - имя файла с путем
//      *Размер          - Число               - размер файла в байтах
//      *Смещение        - Число               - абсолютное смещение файла
//
// Возвращаемое значение:
//  Строка               - вариант распаковки файлов:
//                         если есть файлы с одинаковым именем, то "БезОбщихКаталогов",
//                         в противном случае "БезКаталогов"
//
Функция ВариантРаспаковкиКаталогаПоУмолчанию(ФайлыВАрхиве)

	Для й = 0 По ФайлыВАрхиве.ВГраница() - 1 Цикл
		Для к = й + 1 По ФайлыВАрхиве.ВГраница() Цикл
			Если ФайлыВАрхиве[й].Имя = ФайлыВАрхиве[к].Имя Тогда
				Возврат Перечисления.ВариантыРаспаковкиКаталогов.БезОбщихКаталогов;
			КонецЕсли;
		КонецЦикла;
	КонецЦикла;

	Возврат Перечисления.ВариантыРаспаковкиКаталогов.БезКаталогов;

КонецФункции // ВариантРаспаковкиКаталогаПоУмолчанию()

// Функция - возвращает полный путь к каталогу для распаковки файла
//
// Параметры:
//  ОписаниеФайла        - Структура       - описание файла для распаковки
//      *Имя             - Строка              - имя файла
//      *ПолноеИмя       - Строка              - имя файла с путем
//      *Размер          - Число               - размер файла в байтах
//      *Смещение        - Число               - абсолютное смещение файла
//  КаталогРаспаковки    - Строка         - путь к каталогу для сохранения извлеченных файлов
//  ОбщийПуть            - Строка         - общая для всех файлов часть пути
//  РаспаковкаКаталогов  - Строка         - вариант распаковки каталогов
//
// Возвращаемое значение:
//  Строка               - полный путь к каталогу для распаковки файла
//
Функция КаталогРаспаковкиФайла(ОписаниеФайла, КаталогРаспаковки, ОбщийПуть, РаспаковкаКаталогов)

	Если РаспаковкаКаталогов = Перечисления.ВариантыРаспаковкиКаталогов.ВсеКаталоги Тогда
		КаталогРаспаковкиФайла = ОбъединитьПути(КаталогРаспаковки, ОписаниеФайла.ПолноеИмя);
	ИначеЕсли РаспаковкаКаталогов = Перечисления.ВариантыРаспаковкиКаталогов.БезОбщихКаталогов Тогда
		Путь = Лев(ОписаниеФайла.ПолноеИмя, СтрДлина(ОписаниеФайла.ПолноеИмя) - СтрДлина(ОписаниеФайла.Имя));
		Путь = Сред(Путь, СтрДлина(ОбщийПуть) + 1);
		КаталогРаспаковкиФайла = ОбъединитьПути(КаталогРаспаковки, Путь);
	Иначе
		КаталогРаспаковкиФайла = КаталогРаспаковки;
	КонецЕсли;

	Возврат КаталогРаспаковкиФайла;

КонецФункции // КаталогРаспаковкиФайла()

// Функция - создает необходимые каталоги для указанного пути
//
// Параметры:
//	Путь       - Строка     - проверяемый путь
//	ЭтоФайл    - Булево     - Истина - в параметре "Путь" передан путь к файлу
//                            Ложь - передан каталог
//
// Возвращаемое значение:
//	Булево     - указанный путь доступен
//
Функция ОбеспечитьКаталог(Знач Путь, Знач ЭтоФайл = Ложь) Экспорт
	
	ВремФайл = Новый Файл(Путь);
	
	Если ЭтоФайл Тогда
		Путь = Сред(ВремФайл.Путь, 1, СтрДлина(ВремФайл.Путь) - 1);
		ВремФайл = Новый Файл(Путь);
	КонецЕсли;
	
	Если НЕ ВремФайл.Существует() Тогда
		Если ОбеспечитьКаталог(Сред(ВремФайл.Путь, 1, СтрДлина(ВремФайл.Путь) - 1)) Тогда
			СоздатьКаталог(Путь);
		Иначе
			Возврат Ложь;
		КонецЕсли;
	КонецЕсли;
	
	Если НЕ ВремФайл.ЭтоКаталог() Тогда
		ВызватьИсключение СтрШаблон("По указанному пути ""%1"" не удалось создать каталог", Путь);
	КонецЕсли;
	
	Возврат Истина;
	
КонецФункции // ОбеспечитьКаталог()

#КонецОбласти // СлужебныеПроцедурыИФункции

Лог = ПараметрыПриложения.Лог();
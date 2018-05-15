<?
$connection = \Bitrix\Main\Application::getConnection();
$connection->queryExecute("SET NAMES 'cp1251'");
$connection->queryExecute("SET LOCAL time_zone='".date('P')."'");

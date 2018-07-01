<?
$connection = \Bitrix\Main\Application::getConnection();
$connection->queryExecute("SET NAMES 'utf-8'");
$connection->queryExecute("SET LOCAL time_zone='".date('P')."'");

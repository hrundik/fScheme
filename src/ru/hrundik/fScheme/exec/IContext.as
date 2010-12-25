package ru.hrundik.fScheme.exec
{
	public interface IContext
	{
		function get parentContext():IContext;
	}
}
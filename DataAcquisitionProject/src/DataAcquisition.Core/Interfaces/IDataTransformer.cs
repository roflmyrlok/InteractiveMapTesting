using System.Collections.Generic;

namespace DataAcquisition.Core.Interfaces
{
	public interface IDataTransformer<TSource, TTarget>
	{
		IEnumerable<TTarget> Transform(TSource source);
	}
}
using System;

namespace Tanky.App.Actors
{
    internal interface IDestructable
    {
        IObservable<DefeatedEvent> Destroyed { get; }
    }
}
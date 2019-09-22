using System;

namespace TankyApp.Actors
{
    internal interface IDestructable
    {
        IObservable<DefeatedEvent> Destroyed { get; }
    }
}
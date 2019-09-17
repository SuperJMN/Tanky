using System;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using TankyReloaded.Actors;

namespace TankyReloaded
{
    internal class Stage : IStage
    {
        private readonly ContentManager content;
        private readonly IDisposable enemyAdder;

        private readonly List<IStageObject> objects = new List<IStageObject>();

        public Stage(ContentManager content, double width, double height)
        {
            Width = width;
            Height = height;
            this.content = content;

            enemyAdder = Observable.Interval(TimeSpan.FromSeconds(2)).ObserveOn(Dispatcher.CurrentDispatcher).Subscribe(
                _ => Add(new Ship
                {
                    Top = Utils.Random.Next((int) Constants.GroundTop),
                    Left = width
                }));
        }

        public double Width { get; }
        public double Height { get; }

        public IEnumerable<IStageObject> Objects => objects.AsReadOnly();

        public void AddRelative(IStageObject subject, IStageObject origin, RelativePosition relativePosition)
        {
            if (relativePosition == RelativePosition.Right)
            {
                subject.Left = origin.Left + origin.Width;
                subject.Top = origin.Top + (origin.Height - subject.Height) / 2;
            }

            if (relativePosition == RelativePosition.Left)
            {
                subject.Left = origin.Left - origin.Width;
                subject.Top = origin.Top + (origin.Height - subject.Height) / 2;
            }

            if (relativePosition == RelativePosition.Bottom)
            {
                subject.Left = origin.Left + (origin.Width - subject.Width);
                subject.Top = origin.Top + origin.Height;
            }

            Add(subject);
        }

        public void Update(GameTime gameTime)
        {
            var objs = objects.ToList();

            foreach (var stageObject in objs)
            {
                stageObject.Update(gameTime);
            }

            foreach (var stageObject in objs)
            {
                var others = objs.Except(new[] {stageObject});
                foreach (var other in others)
                {
                    if (stageObject.Collides(other))
                    {
                        stageObject.CollideWith(other);
                        other.CollideWith(stageObject);
                    }
                }
            }
        }

        public void Remove(IStageObject stageObject)
        {
            objects.Remove(stageObject);
        }

        public void Dispose()
        {
            enemyAdder.Dispose();
            foreach (var stageObject in objects)
            {
                if (stageObject is IDisposable d)
                {
                    d.Dispose();
                }
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            foreach (var stageObject in objects)
            {
                stageObject.Draw(spriteBatch);
            }
        }

        public void Add(IStageObject stageObject)
        {
            stageObject.Stage = this;
            objects.Add(stageObject);
            stageObject.LoadContent(content);
        }
    }
}